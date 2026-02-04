# 🎩 Property Manager

**A Monopoly property management dashboard built with Flutter — designed as a state management comparison across branches.**

Each branch implements identical functionality using a different state management approach, while sharing the same pure-Dart business logic (`GameRules`). The backend API and UI are constant — only the state layer changes.

| Branch                  | State Management | Status |
|-------------------------|------------------|--------|
| `main`                  | Variable         | ✅ Complete |
| `feature-provider-base` | Provider         | ✅ Complete |
| `feature-riverpod-base` | Riverpod         | ✅ Complete |
| `feature-cubit-base`    | Bloc/Cubit       | 🔜 Next |

---

## What It Does

Players manage a full Monopoly property portfolio through a single-player dashboard backed by a REST API.

**Property Management** — Purchase, mortgage, unmortgage, and release any of the 28 standard Monopoly properties.

**Improvements** — Build houses and hotels on street properties with full even-build rule enforcement.

**Rent Collection** — Collect rent with accurate calculations: color group double-rent bonus, railroad scaling (1–4 owned), and utility dice-roll multipliers.

**Cash Transactions** — Quick-action buttons for Pass Go, taxes, and fines, plus custom amount entry.

**Game Reset** — Reset to starting state ($1,500, no properties) at any time.

---

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────┐
│   Widgets    │ ──▶ │ State Layer  │ ──▶ │ API Service  │ ──▶  NestJS + PostgreSQL
│  (Flutter)   │ ◀── │ (varies by   │ ◀── │  (shared)    │
│              │     │   branch)    │     │              │
└─────────────┘     └──────┬───────┘     └─────────────┘
                           │
                    ┌──────▼───────┐
                    │  GameRules   │
                    │ (pure Dart)  │
                    └──────────────┘
```

**What stays the same across branches:**
- `GameRules` — Pure Dart game logic, zero dependencies. Rent calculation, even-build enforcement, mortgage rules, asset valuation.
- `ApiService` / `AuthService` — HTTP and local persistence layers.
- Models — `Property`, `Player`, `ColorGroup`, `property_data.dart`.
- All UI widgets (adapted only for state access patterns).

**What changes per branch:**
- The state management class (`GameProvider` → `GameNotifier` → `GameCubit`)
- How widgets read and react to state
- How dialogs and sheets access shared state

---

## Branch Comparison

### Provider (`main`)
- `GameProvider extends ChangeNotifier`
- `context.watch<GameProvider>()` / `context.read<GameProvider>()`
- Dialogs require `ChangeNotifierProvider.value` wrapping to access state
- Manual `_isLoading`, `_error`, `notifyListeners()`

### Riverpod (`riverpod`)
- `GameNotifier extends AsyncNotifier<GameState>`
- `ref.watch(gameNotifierProvider)` / `ref.read(gameNotifierProvider.notifier)`
- Dialogs and sheets access providers directly — no wrapping needed
- `AsyncValue` replaces manual loading/error fields
- Compile-time safety (no runtime provider-not-found errors)

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter / Dart |
| State | Provider · Riverpod · Cubit (by branch) |
| Backend | NestJS · PostgreSQL |
| Hosting | Firebase (web) |
| Game Logic | Pure Dart (`GameRules`) |

---

## Project Structure

```
lib/
├── data/
│   └── property_data.dart         # Static property definitions (28 properties)
├── models/
│   ├── color_group.dart           # Color group enum with house costs
│   ├── player.dart                # Player model
│   └── property.dart              # Property model with rent tiers
├── providers/                     # State layer (varies by branch)
│   ├── game_state.dart            # Immutable state class (Riverpod)
│   ├── game_notifier.dart         # AsyncNotifier (Riverpod)
│   └── providers.dart             # Provider declarations (Riverpod)
├── rules/
│   └── game_rules.dart            # Pure game logic (shared across branches)
├── screens/
│   ├── home_screen.dart           # Main dashboard
│   └── login_screen.dart          # Player selection
├── services/
│   ├── api_config.dart            # API base URL
│   ├── api_service.dart           # REST client
│   └── auth_service.dart          # Local player persistence
└── widgets/
    ├── assets_footer.dart         # Total assets display
    ├── balance_header.dart        # Cash balance + wallet access
    ├── property_deed_dialog.dart  # Full property detail + actions
    ├── property_list.dart         # Scrollable property board
    ├── property_list_item.dart    # Individual property card + rent collection
    └── transaction_sheet.dart     # Cash transaction bottom sheet
```
