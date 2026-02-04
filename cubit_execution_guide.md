# HSOA-Opoly: Riverpod → Cubit Execution Guide

> Working guide for the refactor. Each phase is designed to compile and run before moving to the next.

---

## Architecture At a Glance

```
BEFORE (Riverpod)                       AFTER (Cubit)
─────────────────                       ─────────────
AsyncNotifier<GameState>          →     Cubit<GameState>
ref.watch(gameNotifierProvider)   →     context.watch<GameCubit>()
ref.read(...notifier)             →     context.read<GameCubit>()
AsyncValue (loading/data/error)   →     Sealed class states
.requireValue                     →     state as GameLoaded
ProviderScope                     →     BlocProvider
playerIdProvider (StateProvider)  →     Eliminated — passed to loadGame()
Dialogs just work (global)        →     BlocProvider.value wrapping returns
providers/ directory              →     cubit/ directory
```

**What stays untouched:** `GameRules`, `ApiService`, `AuthService`, `Property`, `Player`, `ColorGroup`, `property_data.dart`, `firebase_options.dart`, `api_config.dart`

---

## Design Decisions

### Sealed Class States vs Status Enum

Two common Cubit patterns for async state:

**Option A — Status enum on a single state class:**
```dart
enum GameStatus { initial, loading, loaded, error }
class GameState {
  final GameStatus status;
  final String? playerId;
  final int? cash;
  // ...nullable everything
}
```

**Option B — Sealed class (one class per state):**
```dart
sealed class GameState { const GameState(); }
class GameInitial extends GameState { ... }
class GameLoading extends GameState { ... }
class GameLoaded extends GameState { ... }
class GameError extends GameState { ... }
```

**Decision: Option B — Sealed classes.** 

Reasons:
- No nullable fields — `GameLoaded` has required `playerId`, `cash`, `properties`. Type system enforces correctness.
- Pattern matching with `switch` is exhaustive — compiler catches missing cases.
- Mirrors what `AsyncValue` was doing for us in Riverpod, just explicit.
- Modern Dart (3.0+) — demonstrates language proficiency in portfolio.

### Dialog/Sheet Provider Scoping

This is the one trade-off vs Riverpod. `BlocProvider` is tree-scoped, so dialogs and bottom sheets (which build in a separate overlay context) can't find the Cubit without wrapping.

**Pattern:**
```dart
showDialog(
  context: context,
  builder: (_) => BlocProvider.value(
    value: context.read<GameCubit>(),
    child: PropertyDeedDialog(propertyId: propertyId),
  ),
);
```

This is simpler than the original Provider version (no `ChangeNotifierProvider.value`, no passing provider instances through constructors), but it's a step back from Riverpod's "dialogs just work" pattern. Worth noting honestly in portfolio discussion.

### Player ID Management

Riverpod had a separate `playerIdProvider` that triggered reactive rebuilds. With Cubit, this is unnecessary — the startup and login flows call `cubit.loadGame(playerId)` imperatively. The player ID lives inside `GameLoaded` state. Simpler.

---

## Phase 1: Infrastructure (no UI changes)

### 1.1 — `pubspec.yaml`

```yaml
# REMOVE
flutter_riverpod: ^2.6.1

# ADD
flutter_bloc: ^9.1.0
```

Run `flutter pub get`.

### 1.2 — Create `lib/cubit/game_state.dart`

Sealed class replacing both the Riverpod `GameState` class and `AsyncValue` handling.

```dart
import '../models/property.dart';
import '../rules/game_rules.dart';

/// Sealed game state — replaces GameState + AsyncValue from Riverpod.
sealed class GameState {
  const GameState();
}

/// No player loaded yet
class GameInitial extends GameState {
  const GameInitial();
}

/// Loading game state from API
class GameLoading extends GameState {
  const GameLoading();
}

/// Game state loaded successfully
class GameLoaded extends GameState {
  final String playerId;
  final int cash;
  final List<Property> properties;

  const GameLoaded({
    required this.playerId,
    required this.cash,
    required this.properties,
  });

  List<Property> get ownedProperties =>
      properties.where((p) => p.isOwned).toList();

  int get totalAssets => GameRules.totalAssets(cash, properties);

  GameLoaded copyWith({
    int? cash,
    List<Property>? properties,
  }) {
    return GameLoaded(
      playerId: playerId,
      cash: cash ?? this.cash,
      properties: properties ?? this.properties,
    );
  }
}

/// Error loading or performing action
class GameError extends GameState {
  final String message;
  const GameError(this.message);
}
```

**Design notes:**
- `GameLoaded` is the equivalent of the old `GameState` class — same fields, same computed getters, same `copyWith`.
- `GameInitial` replaces the "no player ID set" check.
- `GameLoading` replaces `AsyncValue.loading` (only used for initial load).
- `GameError` replaces `AsyncValue.error` — used briefly, then restored to `GameLoaded`.
- Property stays mutable (same pragmatic decision as Riverpod branch).

### 1.3 — Create `lib/cubit/game_cubit.dart`

This is the biggest single change. Convert `GameNotifier` → `GameCubit`.

```dart
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/property_data.dart';
import '../models/property.dart';
import '../rules/game_rules.dart';
import '../services/api_service.dart';
import 'game_state.dart';

class GameCubit extends Cubit<GameState> {
  final ApiService _api;
  final List<Property> _properties;

  GameCubit({ApiService? api})
      : _api = api ?? ApiService(),
        _properties = createInitialProperties(),
        super(const GameInitial());

  /// Load game state for a player. Called from login/startup.
  Future<void> loadGame(String playerId) async {
    emit(const GameLoading());

    try {
      final response = await _api.getGameState(playerId);
      _applyState(response);
      emit(GameLoaded(
        playerId: playerId,
        cash: response.cash,
        properties: _properties,
      ));
    } on ApiException catch (e) {
      emit(GameError(e.message));
    } catch (e) {
      emit(GameError('Connection error: $e'));
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // GAME RULES DELEGATES
  // ─────────────────────────────────────────────────────────────────────────────

  int getActualRentValue(Property property) =>
      GameRules.getActualRentValue(property, _properties);

  String getRentDisplayString(Property property) =>
      GameRules.getRentDisplayString(property, _properties);

  int getRailroadRent(Property property) =>
      GameRules.getRailroadRent(property, _properties);

  int getOwnedRailroadCount() =>
      GameRules.getOwnedRailroadCount(_properties);

  int getOwnedUtilityCount() =>
      GameRules.getOwnedUtilityCount(_properties);

  int getUtilityMultiplier() =>
      GameRules.getUtilityMultiplier(_properties);

  bool hasColorGroupBonus(Property property) =>
      GameRules.hasColorGroupBonus(property, _properties);

  bool canPurchase(Property property) =>
      GameRules.canPurchase(property, _requireLoaded.cash);

  bool canBuildHouse(Property property) =>
      GameRules.canBuildHouse(property, _properties, _requireLoaded.cash);

  bool canBuildHotel(Property property) =>
      GameRules.canBuildHotel(property, _properties, _requireLoaded.cash);

  bool canSellImprovement(Property property) =>
      GameRules.canSellImprovement(property, _properties);

  bool canMortgage(Property property) =>
      GameRules.canMortgage(property, _properties);

  bool canUnmortgage(Property property) =>
      GameRules.canUnmortgage(property, _requireLoaded.cash);

  bool canReleaseProperty(Property property) =>
      GameRules.canReleaseProperty(property, _properties);

  // ─────────────────────────────────────────────────────────────────────────────
  // API ACTIONS
  // ─────────────────────────────────────────────────────────────────────────────

  Future<bool> adjustCash(int amount) =>
      _callApi(() => _api.adjustCash(_requireLoaded.playerId, amount));

  Future<bool> purchaseProperty(Property property) =>
      _callApi(() => _api.purchaseProperty(_requireLoaded.playerId, property.id));

  Future<bool> buildHouse(Property property) =>
      _callApi(() => _api.buildHouse(_requireLoaded.playerId, property.id));

  Future<bool> buildHotel(Property property) =>
      _callApi(() => _api.buildHotel(_requireLoaded.playerId, property.id));

  Future<bool> sellImprovement(Property property) =>
      _callApi(() => _api.sellImprovement(_requireLoaded.playerId, property.id));

  Future<bool> mortgage(Property property) =>
      _callApi(() => _api.mortgage(_requireLoaded.playerId, property.id));

  Future<bool> unmortgage(Property property) =>
      _callApi(() => _api.unmortgage(_requireLoaded.playerId, property.id));

  Future<bool> releaseProperty(Property property) =>
      _callApi(() => _api.releaseProperty(_requireLoaded.playerId, property.id));

  Future<bool> resetGame() =>
      _callApi(() => _api.resetGame(_requireLoaded.playerId));

  // ─────────────────────────────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ─────────────────────────────────────────────────────────────────────────────

  /// Convenience getter — asserts state is loaded.
  /// Used by action methods that should only be called when data exists.
  GameLoaded get _requireLoaded => state as GameLoaded;

  /// Call API and apply returned state. Returns true on success.
  ///
  /// No loading emission for actions — previous state stays visible.
  /// Only loadGame() emits GameLoading.
  Future<bool> _callApi(
    Future<GameStateResponse> Function() apiCall,
  ) async {
    final previous = state;
    if (previous is! GameLoaded) return false;

    try {
      final response = await apiCall();
      _applyState(response);
      emit(GameLoaded(
        playerId: previous.playerId,
        cash: response.cash,
        properties: _properties,
      ));
      return true;
    } on ApiException catch (e) {
      // Brief error, then restore — same pattern as Riverpod branch
      emit(GameError(e.message));
      emit(previous);
      return false;
    } catch (e) {
      emit(GameError('Connection error: $e'));
      emit(previous);
      return false;
    }
  }

  /// Apply API response to local property state.
  void _applyState(GameStateResponse response) {
    final ownedMap = <String, OwnedPropertyResponse>{};
    for (final owned in response.properties) {
      ownedMap[owned.propertyId] = owned;
    }

    for (final property in _properties) {
      final owned = ownedMap[property.id];
      if (owned != null) {
        property.isOwned = true;
        property.houseCount = owned.houseCount;
        property.isMortgaged = owned.isMortgaged;
      } else {
        property.isOwned = false;
        property.houseCount = 0;
        property.isMortgaged = false;
      }
    }
  }
}
```

**Key differences from Riverpod `GameNotifier`:**
- **No `ref`** — Cubit doesn't have a ref system. Dependencies are constructor-injected.
- **No `build()` override** — replaced by explicit `loadGame(playerId)` method. Caller controls when loading happens.
- **No `playerIdProvider`** — player ID is passed to `loadGame()` and stored in `GameLoaded` state.
- **`_requireLoaded` helper** — replaces `state.requireValue`. Same purpose, same assertion.
- **Constructor creates `ApiService` and `_properties`** — in Riverpod these were created in `build()`. Moved to constructor because Cubit is instantiated once and reused.
- **`_callApi` emits states instead of setting `state =`** — semantically identical, different API.

**What's identical:** All game rules delegates, all API action methods, `_applyState`, the `Future<bool>` return pattern, error recovery by restoring previous state.

### 1.4 — No `providers.dart` equivalent needed

Riverpod required a declarations file for provider instances. Cubit doesn't need this — the `GameCubit` is instantiated directly in `BlocProvider`. One less file.

**At this point:** Infrastructure compiles but nothing uses it yet. Old Riverpod files still exist and all UI still imports them.

---

## Phase 2: App Shell

### 2.1 — `lib/main.dart`

**Changes:**
- `ProviderScope` → `BlocProvider<GameCubit>`
- `ConsumerStatefulWidget` → `StatefulWidget`
- Remove all Riverpod imports
- Remove `playerIdProvider` usage — call `cubit.loadGame(playerId)` directly

**Startup flow:**

```
initState()
  └── _checkSavedPlayer()
        ├── No saved player → navigate to LoginScreen
        └── Saved player found
              ├── context.read<GameCubit>().loadGame(playerId)
              └── Listen via BlocListener or stream
                    ├── GameLoaded → navigate to HomeScreen
                    └── GameError → clear saved player, navigate to LoginScreen
```

**Key difference from Riverpod:** We can't `await ref.read(gameNotifierProvider.future)` because Cubit doesn't have a `.future` API. Instead, we listen for state changes:

```dart
// Sketch of the critical logic
Future<void> _checkSavedPlayer() async {
  final savedPlayer = await AuthService.getSavedPlayer();
  if (!mounted) return;

  if (savedPlayer == null) {
    _navigateToLogin();
    return;
  }

  final cubit = context.read<GameCubit>();

  // Listen for load result
  final subscription = cubit.stream.listen((state) {
    if (!mounted) return;
    switch (state) {
      case GameLoaded():
        _navigateToHome();
      case GameError():
        AuthService.clearPlayer().then((_) {
          if (mounted) _navigateToLogin();
        });
      case GameInitial():
      case GameLoading():
        break; // Still loading
    }
  });

  // Trigger load
  cubit.loadGame(savedPlayer);

  // Clean up subscription if widget disposes before result
  // (store subscription in field, cancel in dispose)
}
```

**Alternative (simpler):** Use `await` on `loadGame()` directly since it's a Future. Then check `cubit.state`:

```dart
final cubit = context.read<GameCubit>();
await cubit.loadGame(savedPlayer);
if (!mounted) return;

if (cubit.state is GameLoaded) {
  _navigateToHome();
} else {
  await AuthService.clearPlayer();
  if (mounted) _navigateToLogin();
}
```

**Recommendation: Use the `await` approach.** It's simpler, matches the Riverpod branch's `await ref.read(gameNotifierProvider.future)` pattern, and avoids stream subscription management. The stream approach is more "Bloc-idiomatic" but adds complexity for a one-shot navigation check.

**BlocProvider placement:** Wraps `MaterialApp` so the Cubit is available everywhere:

```dart
runApp(
  BlocProvider(
    create: (_) => GameCubit(),
    child: const MyApp(),
  ),
);
```

---

## Phase 3: Screens

### 3.1 — `lib/screens/login_screen.dart`

**Changes:**
- `ConsumerStatefulWidget` → `StatefulWidget`
- Remove all Riverpod imports, add `flutter_bloc`
- `ref.read(playerIdProvider.notifier).state = matchedPlayer` → `context.read<GameCubit>().loadGame(matchedPlayer)`
- `await ref.read(gameNotifierProvider.future)` → `await cubit.loadGame(matchedPlayer)` then check `cubit.state`

**Login flow:**

```
_handleSubmit()
  ├── Validate name input
  ├── Set local _isLoading = true
  ├── final cubit = context.read<GameCubit>()
  ├── await cubit.loadGame(matchedPlayer)
  │     ├── cubit.state is GameLoaded → AuthService.savePlayer() → navigate to HomeScreen
  │     └── cubit.state is GameError → show error, keep on login
  └── Set local _isLoading = false
```

**Error handling difference:** In Riverpod, failure threw an exception caught by try/catch. With Cubit, `loadGame()` doesn't throw — it emits `GameError`. So we check state after the await:

```dart
final cubit = context.read<GameCubit>();
await cubit.loadGame(matchedPlayer);
if (!mounted) return;

if (cubit.state is GameLoaded) {
  await AuthService.savePlayer(matchedPlayer);
  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const HomeScreen()),
  );
} else if (cubit.state is GameError) {
  setState(() {
    _isLoading = false;
    _errorText = 'Failed to load game: ${(cubit.state as GameError).message}';
  });
}
```

### 3.2 — `lib/screens/home_screen.dart`

**Changes:**
- `ConsumerWidget` → `StatelessWidget`
- `ref.read(gameNotifierProvider.notifier)` → `context.read<GameCubit>()`
- Remove `WidgetRef ref` from build and action methods

**Pattern for action methods:**

```dart
// BEFORE (Riverpod)
final notifier = ref.read(gameNotifierProvider.notifier);
final success = await notifier.adjustCash(200);

// AFTER (Cubit)
final cubit = context.read<GameCubit>();
final success = await cubit.adjustCash(200);
```

Minimal change. The `bool` return pattern is identical.

---

## Phase 4: Widgets

All widgets follow the same conversion pattern.

### Universal Pattern

```dart
// BEFORE (Riverpod)
class SomeWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameNotifierProvider).requireValue;
    // For actions: ref.read(gameNotifierProvider.notifier).someMethod()
  }
}

// AFTER (Cubit)
class SomeWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final state = context.watch<GameCubit>().state as GameLoaded;
    // For actions: context.read<GameCubit>().someMethod()
  }
}
```

**Why `state as GameLoaded`?** Same reasoning as Riverpod's `.requireValue` — these widgets only render after successful data load. The cast is safe because HomeScreen only mounts after `GameLoaded` is emitted.

**For StatefulWidgets** (TransactionSheet): Same pattern, just use `context.watch` / `context.read` directly — no special widget subclass needed (unlike Riverpod's `ConsumerStatefulWidget`).

### 4.1 — `balance_header.dart`

| Change | Detail |
|---|---|
| `ConsumerWidget` → `StatelessWidget` | Remove `WidgetRef ref` param |
| `ref.watch(gameNotifierProvider).requireValue` | `context.watch<GameCubit>().state as GameLoaded` |
| `ref.read(playerIdProvider.notifier).state = null` | Not needed — just clear auth and navigate |
| `_showTransactionSheet`: no wrapping (Riverpod) | **Add** `BlocProvider.value` wrapping |
| `_showLogoutConfirmation`: uses `ref` | Uses `context.read<GameCubit>()` |

**Dialog wrapping returns:**
```dart
// Riverpod — no wrapping needed
void _showTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const TransactionSheet(),
  );
}

// Cubit — BlocProvider.value wrapping needed
void _showTransactionSheet(BuildContext context) {
  final cubit = context.read<GameCubit>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const TransactionSheet(),
    ),
  );
}
```

This is the trade-off mentioned in the design decisions. Tree-scoped providers need explicit forwarding into overlay contexts.

### 4.2 — `property_list.dart`

| Change | Detail |
|---|---|
| `ConsumerWidget` → `StatelessWidget` | |
| `ref.watch(gameNotifierProvider).requireValue.properties` | `(context.watch<GameCubit>().state as GameLoaded).properties` |
| `_showPropertyDetail`: no wrapping (Riverpod) | **Add** `BlocProvider.value` wrapping |

### 4.3 — `property_list_item.dart`

| Change | Detail |
|---|---|
| `ConsumerWidget` → `StatelessWidget` | |
| `ref.read(gameNotifierProvider.notifier)` | `context.read<GameCubit>()` |
| `ref.watch(gameNotifierProvider)` (in `_buildRentInfo`) | `context.watch<GameCubit>()` |

**Utility rent dialog and collect rent dialog:** These create their own dialog contexts. Since `PropertyListItem` already has access to the cubit via its build context, and these dialogs don't need to *watch* state (they only *read* for actions), we can capture the cubit reference before showing the dialog:

```dart
void _collectRent(BuildContext context) {
  final cubit = context.read<GameCubit>();
  // Use cubit directly in dialog callbacks — no wrapping needed
  // because we're only calling methods, not watching state
}
```

This avoids `BlocProvider.value` wrapping for simple action-only dialogs. Only dialogs that need to **watch** state (like `PropertyDeedDialog`) need wrapping.

### 4.4 — `property_deed_dialog.dart`

The biggest widget change.

| Aspect | Riverpod | Cubit |
|---|---|---|
| Class | `ConsumerWidget` | `StatelessWidget` |
| State access | `ref.watch(gameNotifierProvider).requireValue` | `context.watch<GameCubit>().state as GameLoaded` |
| Notifier access | `ref.read(gameNotifierProvider.notifier)` | `context.read<GameCubit>()` |

**Sub-widgets:**
- `_RailroadRentTable` and `_UtilityRentInfo`: currently `ConsumerWidget` → `StatelessWidget`. They watch state and read notifier — same pattern, swap `ref` for `context`.
- `_ActionButtons`: currently `ConsumerWidget` → `StatelessWidget`. Same swap.
- `_PropertyHeader`, `_StatusChip`, `_StreetRentTable`, `_InfoRow`, `_UtilityRentRow`: already `StatelessWidget`, no changes.

**Because `PropertyDeedDialog` is shown via `showDialog`, the calling widget must wrap it:**
```dart
void _showPropertyDetail(BuildContext context, String propertyId) {
  final cubit = context.read<GameCubit>();
  showDialog(
    context: context,
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: PropertyDeedDialog(propertyId: propertyId),
    ),
  );
}
```

### 4.5 — `transaction_sheet.dart`

| Change | Detail |
|---|---|
| `ConsumerStatefulWidget` → `StatefulWidget` | |
| `ConsumerState` → `State` | |
| `ref.read(gameNotifierProvider.notifier)` | `context.read<GameCubit>()` |

Straightforward — the sheet only uses `context.read` for actions, never watches. Local `_isProcessing` / `_errorMessage` state stays as-is.

**Note:** Sheet is shown from `BalanceHeader` which now wraps it in `BlocProvider.value`.

### 4.6 — `assets_footer.dart`

| Change | Detail |
|---|---|
| `ConsumerWidget` → `StatelessWidget` | |
| `ref.watch(gameNotifierProvider).requireValue` | `context.watch<GameCubit>().state as GameLoaded` |

Simplest widget change.

---

## Phase 5: Cleanup

1. **Delete** entire `lib/providers/` directory (`game_notifier.dart`, `game_state.dart`, `providers.dart`)
2. **Search** entire project for any remaining `riverpod` imports (`import 'package:flutter_riverpod/`)
3. **Search** for any remaining `ref.` usage
4. **Run** `dart analyze` — fix any warnings
5. **Test all flows manually:**
   - Login (valid name)
   - Login (invalid name)
   - Auto-login (kill and relaunch)
   - Auto-login with API error (disconnect network, relaunch)
   - Purchase property
   - Build house / hotel
   - Sell improvement
   - Mortgage / unmortgage
   - Release property
   - Collect rent (street, railroad, utility dice roll)
   - Pass Go
   - Cash transaction (receive/pay, custom amount)
   - Reset game
   - Logout / switch player

---

## Quick Reference: Import Changes

Every file that currently imports Riverpod changes to:

```dart
// REMOVE
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/game_state.dart';
import '../providers/game_notifier.dart';

// ADD
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/game_cubit.dart';
import '../cubit/game_state.dart';    // only if accessing state types directly
```

---

## Quick Reference: Access Pattern Changes

| Action | Riverpod | Cubit |
|---|---|---|
| Watch state | `ref.watch(gameNotifierProvider).requireValue` | `context.watch<GameCubit>().state as GameLoaded` |
| Read for actions | `ref.read(gameNotifierProvider.notifier)` | `context.read<GameCubit>()` |
| Check state type | `gameState.when(data:, loading:, error:)` | `switch (state) { case GameLoaded(): ... }` |
| Trigger initial load | Set `playerIdProvider` (reactive) | Call `cubit.loadGame(playerId)` (imperative) |
| Dialog wrapping | None needed | `BlocProvider.value(value: cubit, child: ...)` |

---

## Files Changed vs Unchanged

### Changed (14 files, net same as Riverpod refactor)
| File | Change Type |
|---|---|
| `pubspec.yaml` | Dependency swap |
| `lib/cubit/game_state.dart` | **NEW** (sealed class, replaces providers/game_state.dart) |
| `lib/cubit/game_cubit.dart` | **NEW** (replaces providers/game_notifier.dart) |
| `lib/main.dart` | BlocProvider + startup rewrite |
| `lib/screens/login_screen.dart` | StatefulWidget, imperative load |
| `lib/screens/home_screen.dart` | StatelessWidget |
| `lib/widgets/balance_header.dart` | StatelessWidget, dialog wrapping |
| `lib/widgets/property_list.dart` | StatelessWidget, dialog wrapping |
| `lib/widgets/property_list_item.dart` | StatelessWidget |
| `lib/widgets/property_deed_dialog.dart` | StatelessWidget, biggest refactor |
| `lib/widgets/transaction_sheet.dart` | StatefulWidget |
| `lib/widgets/assets_footer.dart` | StatelessWidget |
| `lib/providers/game_notifier.dart` | **DELETED** |
| `lib/providers/game_state.dart` | **DELETED** |
| `lib/providers/providers.dart` | **DELETED** |

### Unchanged (9 files)
| File | Reason |
|---|---|
| `lib/rules/game_rules.dart` | Pure Dart, no state management |
| `lib/models/property.dart` | Data class |
| `lib/models/player.dart` | Data class (unused but kept for branch parity) |
| `lib/models/color_group.dart` | Enum |
| `lib/data/property_data.dart` | Static factory |
| `lib/services/api_service.dart` | HTTP layer |
| `lib/services/api_config.dart` | Config |
| `lib/services/auth_service.dart` | SharedPreferences |
| `lib/firebase_options.dart` | Generated |

---

## Execution Order

Work bottom-up from infrastructure to UI:

### Phase 1: Infrastructure (no UI changes yet)
1. Update `pubspec.yaml` — swap flutter_riverpod for flutter_bloc, run `pub get`
2. Create `lib/cubit/game_state.dart` — sealed state classes
3. Create `lib/cubit/game_cubit.dart` — convert GameNotifier → GameCubit

### Phase 2: App Shell
4. Update `lib/main.dart` — BlocProvider, convert _AppStartup

### Phase 3: Screens
5. Update `lib/screens/login_screen.dart`
6. Update `lib/screens/home_screen.dart`

### Phase 4: Widgets (order doesn't matter, but this flows naturally)
7. `balance_header.dart`
8. `property_list.dart`
9. `property_list_item.dart`
10. `property_deed_dialog.dart`
11. `transaction_sheet.dart`
12. `assets_footer.dart`

### Phase 5: Cleanup
13. Delete `lib/providers/` directory
14. Remove any remaining Riverpod imports
15. Run `dart analyze`, fix any warnings
16. Test all flows

---

## Portfolio Talking Points

This refactor demonstrates:

1. **Sealed classes replace AsyncValue** — `GameInitial`, `GameLoading`, `GameLoaded`, `GameError` with exhaustive pattern matching. No nullable fields, compiler-enforced state handling.
2. **Simpler dependency model** — no `ref` system, no provider declarations file. Constructor injection for `ApiService`, direct method calls for state changes.
3. **Trade-off awareness** — `BlocProvider.value` wrapping returns for dialogs/sheets (3 instances). This is an honest trade-off vs Riverpod's global provider model, worth discussing.
4. **Widgets return to standard Flutter** — `StatelessWidget` / `StatefulWidget` instead of `ConsumerWidget` / `ConsumerStatefulWidget`. The `context.watch` / `context.read` extensions feel native.
5. **Same business logic** — `GameRules` is identical across Provider, Riverpod, and Cubit branches, proving clean separation of concerns.
6. **Pragmatic immutability** — same approach as Riverpod branch. `GameLoaded` is immutable, `Property` stays mutable. Correctness preserved across all three branches.

### Cross-Branch Comparison (the real portfolio story)

| Aspect | Provider | Riverpod | Cubit |
|---|---|---|---|
| State class | Mutable fields on ChangeNotifier | Immutable GameState + AsyncValue | Sealed class hierarchy |
| Async handling | Manual `_isLoading`/`_error` | `AsyncValue` (built-in) | Sealed states (explicit) |
| Widget types | Standard Flutter | Consumer variants | Standard Flutter |
| Dialog scoping | `ChangeNotifierProvider.value` | None needed | `BlocProvider.value` |
| Provider declarations | Inline in widget tree | Separate declarations file | Inline in widget tree |
| Testability | Context-dependent | Override via ProviderScope | Constructor injection |
| Compile-time safety | ❌ | ✅ | Partial (sealed exhaustiveness) |
| Boilerplate | Low | Low-Medium | Low-Medium |

> "The three branches share identical business logic (`GameRules`), identical models, identical API layer. Only the state management wiring changes. That's the whole point — **the right architecture makes the state management choice a detail, not a commitment.**"
