Title: chore(treemap): harden lookups, centralize layout constants, reduce debug noise

Summary

This PR stabilizes the treemap rendering and hardens several runtime issues observed when running the app on Flutter Web. It contains defensive fixes, centralizes layout constants, reduces noisy debug visuals, and wraps debug logging so it's disabled in release builds.

What I changed

- Hardened unsafe lookups: replaced `firstWhere` usages that could throw with `indexWhere` checks and guarded access in `matrix_page.dart` and other UI entry points.
- Centralized tile sizing: replaced inline min-tile pixel literals with `LayoutConstants.minTileAreaPx` and used `LayoutConstants.minAreaForButtons` for button thresholds.
- Reduced debug visual intensity in `treemap_canvas.dart` (lower alpha, smaller stroke, smaller debug title) but kept `debugTreemap` flag for manual debugging.
- Wrapped `debugPrint` calls with `kDebugMode` to avoid excessive logging in production.
- Created branch `chore/treemap-cleanup` with the changes.

Why

- Prevents full-screen runtime crashes ("Bad state: No element") caused by unsafe lookups.
- Ensures consistent, centralized layout thresholds to avoid tiles being over-filtered and becoming invisible.
- Reduces noisy debug output and extreme debug visuals while preserving the ability to re-enable them for troubleshooting.

Testing & validation

- I ran local test scripts and verified the branch builds; layout use case logs indicate non-empty layouts are produced.
- Manual web runs showed layout computations producing ~20 tiles for demo data in console logs.

Checklist (proposed for PR)

- [x] Harden unsafe lookups (no remaining .firstWhere that can throw in production flows)
- [x] Centralize layout constants and replace inline literals
- [x] Wrap debugPrint with kDebugMode
- [x] Reduce debug visual intensity in treemap painter
- [ ] Confirm tiles are visible in web across themes and minimal mode (manual QA)
- [ ] Remove or gate remaining debug-only artifacts (e.g., temporary visual overrides)
- [ ] Add small unit tests for computeStableLayout sanity (optional follow-up)

Notes & follow-ups

- I left `debugTreemap` gating in place for targeted debugging. We could wire this to a dev-only flag or use asserts for safer toggling.
- There are a few `.firstWhere` usages in tests; I didn't alter tests to avoid changing test semantics, but we can update them if desired.

How to review

Check the branch `chore/treemap-cleanup` and review the modified files (notable ones are under `lib/features/eisen_matrix`). To open a PR on GitHub:

https://github.com/eliezeramaya/eisen/pull/new/chore/treemap-cleanup

If you'd like, I can open the PR for you (requires GitHub API/token) or you can create it from the link above.
