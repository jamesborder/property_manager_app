# HSOA-Opoly: Provider → Riverpod Execution Guide

> Working guide for the refactor. Each phase is designed to compile and run before moving to the next.

---

## Architecture At a Glance

```
BEFORE                                  AFTER
──────                                  ─────
GameProvider (ChangeNotifier)     →     GameNotifier (AsyncNotifier<GameState>)
context.watch<GameProvider>()     →     ref.watch(gameNotifierProvider)
context.read<GameProvider>()      →     ref.read(gameNotifierProvider.notifier)
notifyListeners()                 →     state = AsyncData(newState)
_isLoading / _error fields        →     AsyncValue handles both natively
ChangeNotifierProvider.value()    →     Gone — dialogs/sheets just work
  wrapping dialogs/sheets
```

**What stays untouched:** `GameRules`, `ApiService`, `AuthService`, `Property`, `Player`, `ColorGroup`, `property_data.dart`, `firebase_options.dart`, `api_config.dart`

---

## Phase 1: Infrastructure (no UI changes)

### 1.1 — `pubspec.yaml`

```yaml
# REMOVE
provider: ^6.1.2

# ADD
flutter_riverpod: ^2.6.1
```

Run `flutter pub get`.

### 1.2 — Create `lib/providers/game_state.dart`

Immutable state class replacing the mutable fields on `GameProvider`.

```dart
import '../models/property.dart';
import '../rules/game_rules.dart';

/// Immutable game state — replaces mutable fields on GameProvider
class GameState {
  final String playerId;
  final int cash;
  final List<Property> properties;

  const GameState({
    required this.playerId,
    required this.cash,
    required this.properties,
  });

  List<Property> get ownedProperties =>
      properties.where((p) => p.isOwned).toList();

  int get totalAssets => GameRules.totalAssets(cash, properties);

  GameState copyWith({
    int? cash,
    List<Property>? properties,
  }) {
    return GameState(
      playerId: playerId,
      cash: cash ?? this.cash,
      properties: properties ?? this.properties,
    );
  }
}
```

**Design notes:**
- No `error` field — `AsyncValue.error` handles that.
- No `isLoading` field — `AsyncValue.loading` handles that.
- `Property` stays mutable (Option A from strategy). The `_applyState` method mutates in place, then we create a new `GameState` with a fresh list reference so Riverpod detects the change.
- `Player` class is no longer used here — `playerId` and `cash` live directly on `GameState`. We keep the `Player` file for branch consistency but it's effectively unused.

### 1.3 — Create `lib/providers/game_notifier.dart`

This is the biggest single change. Convert `GameProvider` → `GameNotifier`.

```dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/property_data.dart';
import '../models/property.dart';
import '../rules/game_rules.dart';
import '../services/api_service.dart';
import 'game_state.dart';
import 'providers.dart';

class GameNotifier extends AsyncNotifier<GameState> {
  late final ApiService _api;
  late final List<Property> _properties;

  @override
  Future<GameState> build() async {
    _api = ApiService();
    _properties = createInitialProperties();

    final playerId = ref.watch(playerIdProvider);
    if (playerId == null) {
      throw StateError('No player ID set');
    }

    final response = await _api.getGameState(playerId);
    _applyState(response);

    return GameState(
      playerId: playerId,
      cash: response.cash,
      properties: _properties,
    );
  }

  // ───────────────────────────────────────────────────────────────────────────
  // GAME RULES DELEGATES
  // ───────────────────────────────────────────────────────────────────────────

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
      GameRules.canPurchase(property, state.requireValue.cash);

  bool canBuildHouse(Property property) =>
      GameRules.canBuildHouse(property, _properties, state.requireValue.cash);

  bool canBuildHotel(Property property) =>
      GameRules.canBuildHotel(property, _properties, state.requireValue.cash);

  bool canSellImprovement(Property property) =>
      GameRules.canSellImprovement(property, _properties);

  bool canMortgage(Property property) =>
      GameRules.canMortgage(property, _properties);

  bool canUnmortgage(Property property) =>
      GameRules.canUnmortgage(property, state.requireValue.cash);

  bool canReleaseProperty(Property property) =>
      GameRules.canReleaseProperty(property, _properties);

  // ───────────────────────────────────────────────────────────────────────────
  // API ACTIONS
  // ───────────────────────────────────────────────────────────────────────────

  Future<bool> adjustCash(int amount) =>
      _callApi(() => _api.adjustCash(state.requireValue.playerId, amount));

  Future<bool> purchaseProperty(Property property) =>
      _callApi(() => _api.purchaseProperty(state.requireValue.playerId, property.id));

  Future<bool> buildHouse(Property property) =>
      _callApi(() => _api.buildHouse(state.requireValue.playerId, property.id));

  Future<bool> buildHotel(Property property) =>
      _callApi(() => _api.buildHotel(state.requireValue.playerId, property.id));

  Future<bool> sellImprovement(Property property) =>
      _callApi(() => _api.sellImprovement(state.requireValue.playerId, property.id));

  Future<bool> mortgage(Property property) =>
      _callApi(() => _api.mortgage(state.requireValue.playerId, property.id));

  Future<bool> unmortgage(Property property) =>
      _callApi(() => _api.unmortgage(state.requireValue.playerId, property.id));

  Future<bool> releaseProperty(Property property) =>
      _callApi(() => _api.releaseProperty(state.requireValue.playerId, property.id));

  Future<bool> resetGame() =>
      _callApi(() => _api.resetGame(state.requireValue.playerId));

  // ───────────────────────────────────────────────────────────────────────────
  // INTERNAL HELPERS
  // ───────────────────────────────────────────────────────────────────────────

  /// Call API and apply returned state. Returns true on success.
  ///
  /// We keep the bool return because several call sites use it imperatively
  /// (login flow, transaction sheet confirmation, snackbar feedback).
  /// This is pragmatic — not every action result needs reactive UI.
  Future<bool> _callApi(
    Future<GameStateResponse> Function() apiCall,
  ) async {
    // Preserve current state during loading (don't flash loading indicator
    // for action calls — only build() uses the full AsyncLoading state)
    final previous = state.valueOrNull;

    try {
      final response = await apiCall();
      _applyState(response);
      state = AsyncData(GameState(
        playerId: previous?.playerId ?? response.playerId,
        cash: response.cash,
        properties: _properties,
      ));
      return true;
    } on ApiException catch (e, stack) {
      state = AsyncError(e.message, stack);
      // Restore previous data so widgets don't lose their content
      if (previous != null) {
        state = AsyncData(previous);
      }
      return false;
    } catch (e, stack) {
      state = AsyncError('Connection error: $e', stack);
      if (previous != null) {
        state = AsyncData(previous);
      }
      return false;
    }
  }

  /// Apply API response to local property state
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

**Key decisions captured here:**
- **`_callApi` returns `Future<bool>`** — kept deliberately. Widgets that show snackbars on success/failure use this imperatively. Pure reactive patterns would work but require more widget restructuring than warranted.
- **No loading state on actions** — when a user taps "Buy", the previous state stays visible while the API call runs. Only the initial `build()` shows a full loading state. This matches the current UX.
- **Error recovery** — on API error, we flash `AsyncError` then restore previous data. This lets error-watching widgets react without losing the UI. (Refinement from the strategy doc's `clearError()` pattern — that method is no longer needed.)

### 1.4 — Create `lib/providers/providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'game_notifier.dart';
import 'game_state.dart';

/// Player ID — set on login, null when logged out
final playerIdProvider = StateProvider<String?>((ref) => null);

/// Main game state — auto-loads when playerIdProvider is set
final gameNotifierProvider =
    AsyncNotifierProvider<GameNotifier, GameState>(GameNotifier.new);
```

**At this point:** The infrastructure compiles but nothing uses it yet. Old `game_provider.dart` still exists and all UI still imports it.

---

## Phase 2: App Shell

### 2.1 — `lib/main.dart`

**Changes:**
- Wrap `MyApp` in `ProviderScope`
- `_AppStartup` → `ConsumerStatefulWidget`
- Remove all `GameProvider` / `ChangeNotifierProvider` imports and usage
- Startup flow: check saved player → set `playerIdProvider` → watch `gameNotifierProvider`

**Startup flow detail:**

```
initState()
  └── _checkSavedPlayer()
        ├── No saved player → navigate to LoginScreen
        └── Saved player found
              ├── Set playerIdProvider (triggers gameNotifierProvider.build())
              └── Widget rebuilds via ref.listen on gameNotifierProvider
                    ├── AsyncData → navigate to HomeScreen
                    └── AsyncError → clear saved player, navigate to LoginScreen
```

**Key pattern:** Use `ref.listen` (not `ref.watch`) in `initState` for the one-shot navigation logic. The listener fires when `gameNotifierProvider` transitions from loading → data or loading → error, then navigates accordingly.

```dart
// Sketch of the critical logic (not complete file)
@override
void initState() {
  super.initState();
  _checkSavedPlayer();
}

Future<void> _checkSavedPlayer() async {
  final savedPlayer = await AuthService.getSavedPlayer();
  if (!mounted) return;

  if (savedPlayer == null) {
    _navigateToLogin();
    return;
  }

  // This triggers gameNotifierProvider.build()
  ref.read(playerIdProvider.notifier).state = savedPlayer;

  // Listen for the result
  ref.listenManual(gameNotifierProvider, (previous, next) {
    if (!mounted) return;
    next.when(
      data: (_) => _navigateToHome(),
      error: (_, __) async {
        await AuthService.clearPlayer();
        if (mounted) _navigateToLogin();
      },
      loading: () {}, // Still loading, do nothing
    );
  });
}

void _navigateToHome() {
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const HomeScreen()),
  );
}
```

**What goes away:** The `_navigateToHome(GameProvider provider)` method that passed the provider instance and wrapped in `ChangeNotifierProvider.value`. HomeScreen just navigates clean.

---

## Phase 3: Screens

### 3.1 — `lib/screens/login_screen.dart`

**Changes:**
- `StatefulWidget` → `ConsumerStatefulWidget` (access `ref`)
- Remove manual `GameProvider` creation
- Remove `ChangeNotifierProvider.value` wrapping on navigation
- On successful login: `ref.read(playerIdProvider.notifier).state = matchedPlayer`
- Keep local `_isLoading` / `_errorText` for form UX (simpler than wiring to AsyncValue for a one-shot form)

**Login flow:**

```
_handleSubmit()
  ├── Validate name input
  ├── Set local _isLoading = true
  ├── ref.read(playerIdProvider.notifier).state = matchedPlayer
  ├── await ref.read(gameNotifierProvider.future)   // Wait for build() to complete
  │     ├── Success → AuthService.savePlayer() → navigate to HomeScreen
  │     └── Error → show error, reset playerIdProvider to null
  └── Set local _isLoading = false
```

**Key:** `ref.read(gameNotifierProvider.future)` lets us await the async build imperatively, which fits the form submission pattern cleanly.

**Navigation simplifies to:**
```dart
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const HomeScreen()),
);
```

No more wrapping. This is one of the biggest quality-of-life wins.

### 3.2 — `lib/screens/home_screen.dart`

**Changes:**
- `StatelessWidget` → `ConsumerWidget`
- `context.read<GameProvider>()` → `ref.read(gameNotifierProvider.notifier)`
- Reset dialog: same pattern, just uses `ref.read(...)`

**Pattern for action methods (`_onPassGo`, `_showResetConfirmation`):**

```dart
// BEFORE
final provider = context.read<GameProvider>();
final success = await provider.adjustCash(200);
if (!success) { /* show error using provider.error */ }

// AFTER
final notifier = ref.read(gameNotifierProvider.notifier);
final success = await notifier.adjustCash(200);
if (!success && context.mounted) {
  // Error was briefly in AsyncError state — for snackbar, just show generic
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Failed to collect cash'), backgroundColor: Colors.red),
  );
}
```

**Note on error access:** The old pattern read `provider.error` after a failed action. With our `_callApi` approach (flash error then restore previous data), the error is transient. For snackbar-style feedback, the `bool` return is sufficient. For persistent error display (like in the deed dialog), widgets can watch `gameNotifierProvider` and handle `AsyncError` in their build.

---

## Phase 4: Widgets

All widgets follow the same conversion pattern. They're listed in natural dependency order but can be done in any order.

### Universal Pattern

```dart
// BEFORE
class SomeWidget extends StatelessWidget {
  Widget build(BuildContext context) {
    final provider = context.watch<GameProvider>();
    // use provider.cash, provider.properties, etc.
  }
}

// AFTER
class SomeWidget extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(gameNotifierProvider).requireValue;
    // use state.cash, state.properties, etc.
    // For notifier methods: ref.read(gameNotifierProvider.notifier).canPurchase(p)
  }
}
```

**Why `.requireValue`?** These widgets are only rendered after successful data load (they're children of HomeScreen, which only mounts after `gameNotifierProvider` returns data). Using `.requireValue` keeps the diff minimal — no need for `.when()` in every widget.

**For StatefulWidgets** (TransactionSheet): use `ConsumerStatefulWidget` + `ConsumerState`, access `ref` directly.

### 4.1 — `balance_header.dart`

| Change | Detail |
|---|---|
| `StatelessWidget` → `ConsumerWidget` | Add `WidgetRef ref` param |
| `context.watch<GameProvider>()` | `ref.watch(gameNotifierProvider).requireValue` |
| `_showTransactionSheet`: remove `ChangeNotifierProvider.value` wrap | Just show `TransactionSheet()` directly |
| Logout: add `ref.read(playerIdProvider.notifier).state = null` | Clear Riverpod state on logout |

**The `ChangeNotifierProvider.value` wrapping in `_showTransactionSheet` goes away entirely.** This is the simplification the strategy doc highlighted:

```dart
// BEFORE
void _showTransactionSheet(BuildContext context) {
  final provider = context.read<GameProvider>();
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => ChangeNotifierProvider.value(
      value: provider,
      child: const TransactionSheet(),
    ),
  );
}

// AFTER
void _showTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const TransactionSheet(),
  );
}
```

### 4.2 — `property_list.dart`

| Change | Detail |
|---|---|
| `StatelessWidget` → `ConsumerWidget` | |
| `context.watch<GameProvider>().properties` | `ref.watch(gameNotifierProvider).requireValue.properties` |
| `_showPropertyDetail`: remove `ChangeNotifierProvider.value` wrap | Just show `PropertyDeedDialog(...)` directly |

Same dialog simplification as BalanceHeader.

### 4.3 — `property_list_item.dart`

| Change | Detail |
|---|---|
| `StatelessWidget` → `ConsumerWidget` | For `_buildRentInfo`'s watch |
| `context.watch<GameProvider>()` in `_buildRentInfo` | `ref.read(gameNotifierProvider.notifier)` for game rules methods |
| `context.read<GameProvider>()` in `_collectRent` | `ref.read(gameNotifierProvider.notifier)` |

**Nuance:** `_buildRentInfo` currently uses `context.watch` to get the provider for `getRentDisplayString` and `hasColorGroupBonus`. These are computed from current state, so we need `ref.watch(gameNotifierProvider)` to rebuild when state changes. The notifier methods read from the live `_properties` list.

**Utility rent dialog:** Uses `provider.getUtilityMultiplier()` and `provider.adjustCash()`. Both become `ref.read(gameNotifierProvider.notifier).methodName()`. The dialog doesn't need wrapping since Riverpod providers are global.

**`_PropertyStatusBadge`:** No provider access — stays as-is (pure widget, reads from `Property` directly).

### 4.4 — `property_deed_dialog.dart`

The biggest widget change. Currently uses `context.watch<GameProvider>()` for:
- Property lookup (`provider.properties.firstWhere(...)`)
- Loading state (`provider.isLoading`)
- Error state (`provider.error`)
- All game rules delegates
- All action methods

**Changes:**

| Aspect | Before | After |
|---|---|---|
| Class | `StatelessWidget` | `ConsumerWidget` |
| Property lookup | `provider.properties.firstWhere(...)` | `state.properties.firstWhere(...)` |
| Loading indicator | `provider.isLoading` | Remove — actions don't flash loading state |
| Error banner | `provider.error` / `provider.clearError()` | Remove `_ErrorBanner` — errors are transient, handled by bool return |
| Game rules | `provider.canPurchase(p)` | `ref.read(gameNotifierProvider.notifier).canPurchase(p)` |
| Actions | `provider.purchaseProperty(p)` | `ref.read(gameNotifierProvider.notifier).purchaseProperty(p)` |
| `_isDisabled` | `provider.isLoading` | Can use local state if we want to disable during API calls, or remove |

**On removing `_ErrorBanner` and `clearError()`:** The current pattern shows a persistent error banner in the dialog that the user dismisses. With `_callApi` restoring previous state on error, the error is transient and the `bool` return from action methods handles snackbar feedback. If we want to keep a persistent error in the dialog, we can add local `String? _error` state to a `ConsumerStatefulWidget` — but that's more code for questionable UX value. **Recommendation: remove it, use snackbar feedback from bool return, keep the widget as `ConsumerWidget`.**

**Sub-widgets (`_ActionButtons`, `_RailroadRentTable`, `_UtilityRentInfo`):** These currently take `GameProvider provider` as a constructor param. Change to take `GameNotifier notifier` or access via `ref` if converted to `ConsumerWidget`. Simplest approach: make `_ActionButtons` a `ConsumerWidget` so it can access `ref` directly. For `_RailroadRentTable` and `_UtilityRentInfo`, pass the notifier as a param (they just read computed values).

### 4.5 — `transaction_sheet.dart`

| Change | Detail |
|---|---|
| `StatefulWidget` → `ConsumerStatefulWidget` | Keeps `TextEditingController`, local form state |
| `context.read<GameProvider>()` | `ref.read(gameNotifierProvider.notifier)` |

This is straightforward — the sheet only uses `context.read` for actions, never `context.watch`. Local `_isProcessing` / `_errorMessage` state stays as-is.

### 4.6 — `assets_footer.dart`

| Change | Detail |
|---|---|
| `StatelessWidget` → `ConsumerWidget` | |
| `context.watch<GameProvider>()` | `ref.watch(gameNotifierProvider).requireValue` |
| `provider.totalAssets` | `state.totalAssets` |
| `provider.ownedProperties.length` | `state.ownedProperties.length` |

Simplest widget change — just swap the access pattern.

---

## Phase 5: Cleanup

1. **Delete** `lib/providers/game_provider.dart`
2. **Search** entire project for any remaining `provider` package imports (`import 'package:provider/`)
3. **Run** `dart analyze` — fix any warnings
4. **Test all flows manually:**
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

Every file that currently imports `package:provider/provider.dart` changes to:

```dart
// REMOVE
import 'package:provider/provider.dart';
import '../providers/game_provider.dart';

// ADD
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/providers.dart';
import '../providers/game_state.dart';    // only if accessing GameState directly
import '../providers/game_notifier.dart'; // only if accessing GameNotifier type
```

---

## Files Changed vs Unchanged

### Changed (14 files)
| File | Change Type |
|---|---|
| `pubspec.yaml` | Dependency swap |
| `lib/providers/game_state.dart` | **NEW** |
| `lib/providers/game_notifier.dart` | **NEW** (replaces game_provider.dart) |
| `lib/providers/providers.dart` | **NEW** |
| `lib/main.dart` | ProviderScope + startup rewrite |
| `lib/screens/login_screen.dart` | ConsumerStatefulWidget |
| `lib/screens/home_screen.dart` | ConsumerWidget |
| `lib/widgets/balance_header.dart` | ConsumerWidget, dialog unwrap |
| `lib/widgets/property_list.dart` | ConsumerWidget, dialog unwrap |
| `lib/widgets/property_list_item.dart` | ConsumerWidget |
| `lib/widgets/property_deed_dialog.dart` | ConsumerWidget, biggest refactor |
| `lib/widgets/transaction_sheet.dart` | ConsumerStatefulWidget |
| `lib/widgets/assets_footer.dart` | ConsumerWidget |
| `lib/providers/game_provider.dart` | **DELETED** |

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

## Portfolio Talking Points

This refactor demonstrates:

1. **AsyncValue replaces three manual fields** — `_isLoading`, `_error`, and `notifyListeners()` all collapse into `AsyncValue<GameState>`
2. **Dialog/sheet provider scoping eliminated** — the `ChangeNotifierProvider.value` wrapping pattern disappears entirely (3 instances removed)
3. **Compile-time safety** — `ref.watch(gameNotifierProvider)` can't fail silently the way `context.read<GameProvider>()` can when the provider isn't in the ancestor tree
4. **Testability** — providers can be overridden in tests via `ProviderScope(overrides: [...])` without building a widget tree
5. **Same business logic** — `GameRules` is identical across Provider, Riverpod, and (future) Cubit branches, proving clean separation of concerns
6. **Pragmatic immutability** — `GameState` is immutable while `Property` stays mutable. Correctness preserved, diff minimized. Full immutability is a follow-up, not a blocker.