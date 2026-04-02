# WiFi Watchtower Project Map

Default workspace: use `apps/wifi-watchtower` when working inside this repository. Otherwise pass `--workspace /path/to/wifi-watchtower` to the runner.

## Target

- `WifiWatchtower`: macOS SwiftUI menu bar app with a dashboard window and `MenuBarExtra` entry point

## Main Files

- `project.yml`: XcodeGen spec for the app and unit-test targets
- `WifiWatchtowerApp/Info.plist`: app metadata for the menu bar utility
- `WifiWatchtowerApp/Sources/App/WifiWatchtowerApp.swift`: app entry point, dashboard window, and menu bar scene
- `WifiWatchtowerApp/Sources/App/WatchtowerModel.swift`: refresh loop, top-level app state, and dashboard handoff
- `WifiWatchtowerApp/Sources/Models/NetworkSnapshot.swift`: trust-level enums, scoring models, and snapshot presentation helpers
- `WifiWatchtowerApp/Sources/Services/WifiInspector.swift`: CoreWLAN capture, routing checks, nearby-network scoring, and recommendation logic
- `WifiWatchtowerApp/Sources/Services/WifiTrustScorer.swift`: testable trust-scoring helper used by the inspector and unit tests
- `WifiWatchtowerApp/Sources/Views/MenuBarView.swift`: compact menu bar panel
- `WifiWatchtowerApp/Sources/Views/DashboardView.swift`: larger dashboard view for explanations and nearby-network context
- `WifiWatchtowerApp/Tests/WifiTrustScorerTests.swift`: deterministic coverage for open-network avoidance and secure-hotspot scoring
- `scripts/run_wifi_watchtower.sh`: thin wrapper around the shared runner in `skills/network-studio/scripts/run_wifi_watchtower.sh`

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_wifi_watchtower.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_wifi_watchtower.sh --workspace /path/to/wifi-watchtower <command>`
- `generate` uses `xcodegen`.
- `open` launches `WifiWatchtower.xcodeproj`.
- `typecheck` runs `swiftc` against `WifiWatchtowerApp/Sources` for a fast source-level pass.
- `build` uses `xcodebuild` with a local `.build-debug` derived-data folder.
- `test` uses `xcodebuild test` against the `WifiWatchtowerTests` bundle.
- `run` builds and opens `WifiWatchtower.app` from `.build-debug/Build/Products/Debug`.

## Constraints

- Keep the app menu-bar-first and compact.
- Preserve local-only Wi-Fi inspection and scoring. Do not add remote telemetry or account-bound sync by default.
- Treat trust grades as guidance, not proof of compromise.
- Keep current-network trust signals separate from nearby-network context so the UI stays honest.
