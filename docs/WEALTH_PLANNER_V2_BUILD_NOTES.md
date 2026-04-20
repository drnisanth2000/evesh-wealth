# Wealth Planner v2 — Build Notes

Short, blunt, scannable reference for anyone (human or subagent) touching the
Wealth Planner v2 refactor. Master plan: `/Users/nisanth/.claude/plans/let-us-now-plan-swift-badger.md`.

---

## 1. Ground rules (read first)

Every one of these was learned the hard way in Phases 0–2. Do not skip.

1. **This working copy is NOT a git repo.** Never run `git add`, `git commit`, `git status`, `git diff`, `git log`, `git push`, `git pull`. Skip every "commit step" you see in plans. If you feel an urge to commit, stop.
2. **Supabase migrations** are pushed with the CLI from the `evesh_wealth/` directory. `supabase init` has already been run once.
   ```
   SUPABASE_ACCESS_TOKEN=sbp_cc9734be49808558fe6bab86906187b01d4ca26e \
     supabase db push --linked
   ```
   Project ref: `bewtjsjhdtwhrsshmigm`. Use `supabase migration list --linked` to see remote state.
3. **Flutter binary**: `/opt/homebrew/share/flutter/bin/flutter`. Flutter 3.41.5 / Dart 3.11.3.
4. **Always pass `--timeout=30s` to `flutter test`.** Hangs in this codebase are common; a timeout turns a hang into a failure you can diagnose.
5. **No new comments except why-comments.** The codebase already follows this — match it.
6. **Riverpod codegen only.** `@riverpod` for functions, `@Riverpod(keepAlive: true)` for stateful notifiers. Mutator convention:
   ```dart
   @riverpod
   class XMutator extends _$XMutator {
     @override
     void build() {}
     Future<void> doThing(...) async { ... }
   }
   ```
   See `lib/presentation/providers/other_assets_provider.dart` and `goal_provider.dart` for canonical patterns. Don't hand-roll `StateNotifier` classes.
7. **Freezed for DB models only.** Plain Dart classes for domain/computation intermediaries (e.g. `BucketComposition`, `DeploymentPlan` calc output).
8. **Palette tokens live in `lib/core/theme/app_palette.dart` (context-aware) and `lib/core/theme/app_colors.dart` (brand).** Never introduce new color constants anywhere else.
9. **DB ↔ enum bridges are explicit methods, never `.name`:**
   - `AssetClass.fromString(dbString)` / `AssetClass.dbValue`
   - `TaxCategory.fromString(dbString)` / `TaxCategory.dbValue`
   - `AssetType.fromString(dbString)` / `AssetType.dbValue`
10. **`go_router` rebuilds on auth state change.** Don't call `refreshSession()` from UI flows and don't add extra auth watches to the router provider — you'll cause infinite rebuild loops.
11. **Hive boxes are opened once in `main.dart`:** `nav_cache`, `fund_list`, `portfolio_snapshot`, `user_prefs`. Reuse `user_prefs` with a namespaced key before opening a new box.
12. **Selected member is global.** Always `ref.watch(selectedMemberProvider)`. Never reintroduce a local `_selectedMemberId` — Dashboard and ActionCenter have already been migrated.

---

## 2. Testing that works / testing that hangs

Based on real hangs from this session — not general advice.

### DO

- **Pure-function unit tests** (no Riverpod, no Hive). Instant and reliable. Prefer these for `bucket_mapping`, enum parsing, computed helpers.
- **Freezed round-trip JSON tests.** Write a fixture map, `Model.fromJson` → `.toJson`, assert equality.
- **Minimal widget tests:** one `pumpAndSettle` after `pumpWidget`, then assert on `find.text(...)`. Fast, deterministic.
- **Hive setup in tests:**
  ```dart
  late Directory tempDir;
  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('evesh_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>('user_prefs');
  });
  tearDown(() async { await Hive.box<dynamic>('user_prefs').clear(); });
  tearDownAll(() async { await Hive.close(); await tempDir.delete(recursive: true); });
  ```
  **Do NOT `Hive.initFlutter()`** — it calls `path_provider`, which has no flutter_test implementation and will hang or throw.
- **Fake notifier providers** via `overrideWith` with a `_Fake extends Notifier` subclass for preset state. See `test/presentation/widgets/wealth_planner/global_member_header_test.dart` for the `_FakeSelected extends SelectedMember` pattern.

### DO NOT

- **Tap a widget and then `pumpAndSettle` expecting provider state to have landed.** If the write is `await box.put(...)`, it does not drain via frame pumps. We burned 30+ minutes on this. Two workable options:
  1. Call the notifier method directly in the test instead of tapping.
  2. Ensure the notifier sets `state = ...` *synchronously before* the `await` on persistence. `selected_member_provider.dart` does this — look there for the ordering.
- **`overrideWith((ref) async => [...])` on a family provider**, then rely on `pumpAndSettle` to resolve. It does not always settle. Either override with a sync provider or inject a fake notifier.
- **Pipe `flutter test` output through `| tail -N`.** Output is buffered until the process exits — a hang becomes invisible. Use:
  ```
  flutter test --timeout=30s path/to/test 2>&1 | tee /tmp/test.txt
  ```
  and `Monitor` the `/tmp/test.txt` file for progress.

---

## 3. Build / deploy commands

All run from `evesh_wealth/` unless noted.

| Task | Command |
| --- | --- |
| Regenerate codegen | `dart run build_runner build --delete-conflicting-outputs` |
| Analyze (targeted) | `flutter analyze <file1> <file2>` — never whole repo (462 pre-existing lints) |
| Run a single test | `flutter test --timeout=30s test/path/to/x_test.dart` |
| Push migrations | `SUPABASE_ACCESS_TOKEN=sbp_cc9734be49808558fe6bab86906187b01d4ca26e supabase db push --linked` |
| List remote migrations | `SUPABASE_ACCESS_TOKEN=... supabase migration list --linked` |
| Production web build | `flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...` |
| Deploy to Netlify | `netlify deploy --prod --dir=build/web` |

---

## 4. Wealth Planner v2 topology so far

- **Bucket mapping (core):** `lib/core/constants/bucket_mapping.dart` — `Bucket` enum (`liquid`, `fixedIncome`, `growth`); `bucketFor(AssetClass, TaxCategory?)` for MF; `bucketForAssetType(AssetType)` for other assets. Hybrid-E → Growth, Hybrid-D → Fixed Income.
- **Global member state:** `lib/presentation/providers/selected_member_provider.dart` — persisted via Hive `user_prefs` box.
- **Global header widget:** `lib/presentation/widgets/wealth_planner/global_member_header.dart` — chip row bound to `selectedMemberProvider`.
- **Shell:** `lib/presentation/screens/wealth_planner/wealth_planner_shell.dart` — three top tabs (MF / Allocation / Rebalance).
- **MF tab host:** `lib/presentation/screens/wealth_planner/tabs/mf_tab.dart`, wrapping three sub-tabs:
  - `sub/mf_current_tab.dart` (done)
  - `sub/mf_buy_tab.dart` (stub)
  - `sub/mf_order_status_tab.dart` (stub)
- **UI atoms (Current tab):** `lib/presentation/widgets/wealth_planner/asset_class_card.dart`, `holding_row.dart`.
- **Freezed models:** `pending_order_model.dart`, `rebalance_dismissal_model.dart`, `deployment_plan_model.dart`, `other_asset_model.dart` (all under `lib/data/models/`).
- **Keystone provider:** `lib/presentation/providers/bucket_composition_provider.dart` — merges portfolio + other assets + risk targets + goals into 3 buckets.
- **Supabase migration 047:** adds `pending_orders`, `rebalance_dismissals`, `deployment_plans` tables + `bucket_override` column on `other_assets` and `transactions`.
- **Routes:** `/wealth-planner` (shell), `/wealth-planner/mf`, `/wealth-planner/allocation`, `/wealth-planner/rebalance`, `/wealth-planner/legacy` (old dashboard kept for one release).

---

## 5. Specific failure modes to avoid repeating

- **Subagents attempting git operations** despite explicit "no git" instructions. Repeat "no git" at the top AND bottom of every subagent prompt.
- **`| tail` piping** on `flutter test` hides hangs. Always `tee` to a file.
- **Async-Riverpod-override + Hive-write + `pumpAndSettle`** is the guaranteed-hang recipe. Restructure the test.
- **Scope creep**: subagents editing `app_palette.dart`, touching unrelated screens "for consistency", etc. Only modify files explicitly listed in the task.
- **Repo-wide `flutter analyze`** produces 462 pre-existing info-level lints and buries real issues. Analyze only the touched files.
- **Local `_selectedMemberId` in screens.** Dashboard and ActionCenter were fully migrated to `selectedMemberProvider`. Do not reintroduce local state.

---

## 6. Current state snapshot

| Phase | Status | Notes |
| --- | --- | --- |
| Phase 0 — Foundations (bucket mapping, models, migration 047, providers scaffolding) | Done | 70 tests pass |
| Phase 1 — Shell + global member header + router wiring | Done | 11 tests pass |
| Phase 2.1 — MF tab host + 3 sub-tab stubs | Done | — |
| Phase 2.2 + 2.3 — MF Current tab: asset class cards + holding rows | Done | — |
| Phase 2.4 — MF Buy tab (MFScreener + "Save to Watchlist" / "Mark as Bought") | Pending | — |
| Phase 2.5 — MF Order Status tab (`pending_orders` feed + filter chips) | Pending | — |
| Phase 3 — Asset Allocation tab (Bucket / Asset / Fund sub-tabs) | Pending | — |
| Phase 4 — Rebalance tab (Suggested / Deployment / Dismissed) | Pending | — |
| Phase 5 — Legacy cleanup, route removals, orphan deletion | Pending | — |

---

## 7. Copy-paste subagent prompt prelude

Paste this verbatim at the TOP of every Phase 2–5 subagent dispatch:

```
GROUND RULES (do not skip):
1. This working copy is NOT a git repo. Do not run git add/commit/status/diff/log/push/pull. No commit step, ever.
2. Only modify files in the explicit file list I give you. No opportunistic cleanup of unrelated files (palette, other screens, etc).
3. Tests: always `flutter test --timeout=30s <file>`. Never pipe output through `| tail` — use `2>&1 | tee /tmp/test.txt` so hangs are visible. Never `Hive.initFlutter()` in tests — use `Directory.systemTemp.createTemp()` + `Hive.init(path)`.
4. Do NOT use `pumpAndSettle` to wait for `await box.put()` to resolve. Call the notifier directly or set `state =` before the await.
5. Analyze only the files you touched: `flutter analyze file1 file2`. Never repo-wide (462 pre-existing lints).
6. Riverpod codegen only. Mutator pattern: `@riverpod class XMutator extends _$XMutator { @override void build() {} ... }`. See `other_assets_provider.dart`.
7. Freezed for DB models; plain Dart for domain/computation.
8. Palette tokens in `app_palette.dart` / `app_colors.dart` only. No new color constants.
9. DB ↔ enum via `AssetClass.fromString`, `TaxCategory.fromString`, `AssetType.dbValue` — never `.name`.
10. Supabase migrations: `SUPABASE_ACCESS_TOKEN=sbp_cc9734be49808558fe6bab86906187b01d4ca26e supabase db push --linked` from `evesh_wealth/`. Project ref: `bewtjsjhdtwhrsshmigm`.
11. Selected member is global via `selectedMemberProvider`. Never reintroduce local `_selectedMemberId`.
12. Codegen after adding any @Freezed or @riverpod: `dart run build_runner build --delete-conflicting-outputs`.

Reference: `evesh_wealth/docs/WEALTH_PLANNER_V2_BUILD_NOTES.md` and
`/Users/nisanth/.claude/projects/.../memory/feedback_wealth_planner_v2.md`.
```
