# Flight Scout Project Map

Default workspace: use `apps/flight-scout` when working inside this repository. Otherwise pass `--workspace /path/to/flight-scout` to the runner.

## Target

- `FlightScout`: macOS SwiftUI menu bar app with a status item, popover, and board window
- `VibeWidgetCore`: shared framework target inside the workspace; keep it in sync with `FlightScout` scheme dependencies

## Main Files

- `project.yml`: XcodeGen spec for both targets
- `FlightScoutApp/Info.plist`: accessory app metadata
- `FlightScoutApp/Sources/App/FlightScoutApp.swift`: app entry point and settings scene
- `FlightScoutApp/Sources/App/FlightScoutStatusBarController.swift`: status item, popover, board window, and quit menu
- `FlightScoutApp/Sources/App/FlightScoutAppModel.swift`: refresh loop, settings, ranking, exports, and UI state
- `FlightScoutApp/Sources/App/FlightScoutModels.swift`: domain models and enums for regions, routes, risk, and filters
- `FlightScoutApp/Sources/App/FlightScoutSettingsStore.swift`: persisted preferences and defaults
- `FlightScoutApp/Sources/Services/FlightScoutEngine.swift`: live refresh orchestration and source aggregation
- `FlightScoutApp/Sources/Services/FlightScoutRankingService.swift`: deterministic and AI-assisted route ranking
- `FlightScoutApp/Sources/Services/FlightPriceSearchService.swift`: public fare signal extraction and page parsing
- `FlightScoutApp/Sources/Services/FlightRiskFeedService.swift`: risk source ingest and normalization
- `FlightScoutApp/Sources/Services/FlightRouteResolverService.swift`: origin and destination resolution
- `FlightScoutApp/Sources/Services/OfficialTravelAdvisoryService.swift`: official travel advisory parsing
- `FlightScoutApp/Sources/Services/FlightWeatherService.swift`: weather risk inputs
- `FlightScoutApp/Sources/Services/VPNRegionService.swift`: current VPN region detection
- `FlightScoutApp/Sources/Views/FlightScoutMenuBarView.swift`: compact menu bar popover
- `FlightScoutApp/Sources/Views/FlightScoutBoardView.swift`: larger board for routes, risk, and settings
- `FlightScoutApp/Tests/FlightScoutTests.swift`: parser, ranking, advisory, and export coverage
- `VibeWidgetCore/Sources`: shared helper framework used by this workspace

## Run And Build Notes

- Use the runner script first: `bash scripts/run_flight_scout.sh <command>`
- If the app lives outside the current repo, use: `bash scripts/run_flight_scout.sh --workspace /path/to/flight-scout <command>`
- `generate` uses `xcodegen`.
- `open` launches `FlightScout.xcodeproj`.
- `build` and `test` use `xcodebuild` with a local `.build-debug` derived-data folder.
- `run` builds and opens `FlightScout.app` from `.build-debug/Build/Products/Debug`.

## Constraints

- Keep the app menu-bar-first and compact.
- Preserve local source-based price and risk signals; do not invent live data or hide fallback freshness.
- Keep the shared `VibeWidgetCore` target consistent with the scheme and imports.
