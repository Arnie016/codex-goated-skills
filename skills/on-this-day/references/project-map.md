# On This Day Bar Project Map

Default workspace: use `apps/on-this-day-bar` when working inside this repository. Otherwise pass `--workspace /path/to/on-this-day-bar` to the runner.

## Target

- `OnThisDayBar`: macOS SwiftUI menu bar app with cached-feed fallback and a settings scene

## Main Files

- `project.yml`: XcodeGen spec for the app and unit-test target
- `OnThisDayBarApp/Info.plist`: menu-bar-only metadata
- `OnThisDayBarApp/Sources/App/OnThisDayBarApp.swift`: app entry point and settings scene wiring
- `OnThisDayBarApp/Sources/App/OnThisDayBarAppModel.swift`: date navigation, category selection, and user-facing state
- `OnThisDayBarApp/Sources/App/OnThisDayBarModels.swift`: feed and presentation models
- `OnThisDayBarApp/Sources/Services/OnThisDayFeedService.swift`: live Wikimedia fetch and decode path
- `OnThisDayBarApp/Sources/Services/OnThisDayStore.swift`: local cache and fallback state
- `OnThisDayBarApp/Sources/Views/OnThisDayBarMenuBarView.swift`: compact menu bar UI
- `OnThisDayBarApp/Sources/Views/OnThisDayBarSettingsView.swift`: default-category and story-depth settings
- `OnThisDayBarApp/Sources/Views/OnThisDayBarTheme.swift`: app-level styling tokens
- `OnThisDayBarApp/Tests/OnThisDayBarTests.swift`: date, feed, and view-model coverage

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_on_this_day_bar.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_on_this_day_bar.sh --workspace /path/to/on-this-day-bar <command>`
- `generate` uses `xcodegen`.
- `open` launches `OnThisDayBar.xcodeproj`.
- `build` and `test` use `xcodebuild` with a local `.build-debug` derived-data folder.
- `run` builds and opens `OnThisDayBar.app` from `.build-debug/Build/Products/Debug`.

## Constraints

- Keep the app grounded in the official Wikimedia feed; do not add invented summaries or unverified fallback facts.
- Preserve explicit stale-data messaging when cache is used.
- Keep the popover compact and menu-bar-first instead of turning it into a large history browser window.
