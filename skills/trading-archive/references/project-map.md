# Trading Archive Project Map

Default workspace: use `apps/trading-archive-bar` when working inside this repository. Otherwise pass `--workspace /path/to/trading-archive-bar` to the runner.

## Target

- `TradingArchiveBar`: macOS SwiftUI menu bar app for browsing archived trading articles, live feed refreshes, search, favorites, and cached fallback

## Main Files

- `project.yml`: XcodeGen spec for the app and unit-test target
- `TradingArchiveBarApp/Info.plist`: menu-bar-only app metadata
- `TradingArchiveBarApp/Sources/App/TradingArchiveBarApp.swift`: app entry point and settings scene wiring
- `TradingArchiveBarApp/Sources/App/TradingArchiveBarAppModel.swift`: refresh loop, filtering, favorites, and user-facing state
- `TradingArchiveBarApp/Sources/App/TradingArchiveBarModels.swift`: domain models and presentation helpers
- `TradingArchiveBarApp/Sources/Services/TradingArchiveFeedService.swift`: live RSS or Atom fetch, parse, and dedupe flow
- `TradingArchiveBarApp/Sources/Services/TradingArchiveStore.swift`: cached snapshot, preferences, and favorites persistence
- `TradingArchiveBarApp/Sources/Views/TradingArchiveBarMenuBarView.swift`: compact menu bar popover
- `TradingArchiveBarApp/Sources/Views/TradingArchiveBarSettingsView.swift`: feed URL and archive-depth settings scene
- `TradingArchiveBarApp/Sources/Views/TradingArchiveBarTheme.swift`: app-level styling tokens and reusable views
- `TradingArchiveBarApp/Tests/TradingArchiveBarTests.swift`: parser, cache, and filtering coverage
- `product-spec.md`: product shape, fallback behavior, settings UX, and artifact expectations
- `../scripts/fetch_trading_feeds.py`: deterministic archive snapshot helper

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_trading_archive.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_trading_archive.sh --workspace /path/to/trading-archive-bar <command>`
- `fetch` runs the deterministic feed helper and can emit markdown or JSON snapshots.
- `generate` uses `xcodegen`.
- `open` launches `TradingArchiveBar.xcodeproj`.
- `build` and `test` use `xcodebuild` with a local `.build-debug` derived-data folder.
- `run` builds and opens `TradingArchiveBar.app` from `.build-debug/Build/Products/Debug`.

## Constraints

- Keep the product grounded in public or user-authorized RSS and Atom feeds.
- Preserve explicit cached-state messaging when live feeds fail.
- Keep the popover compact and menu-bar-first instead of turning it into a large reading app window.
