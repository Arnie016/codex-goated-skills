# Phone Spotter Project Map

Default workspace: use `apps/phone-spotter` when working inside this repository. Otherwise pass `--workspace /path/to/phone-spotter` to the runner.

## Target

- `PhoneSpotter`: macOS SwiftUI menu bar app with `LSUIElement` enabled

## Main Files

- `project.yml`: XcodeGen spec for the app and unit-test target
- `PhoneSpotterApp/Info.plist`: menu-bar-only metadata
- `PhoneSpotterApp/Sources/App/PhoneSpotterApp.swift`: app entry point and settings scene
- `PhoneSpotterApp/Sources/App/PhoneSpotterAppModel.swift`: app state, provider handoff actions, clue capture, and pairing flow
- `PhoneSpotterApp/Sources/App/PhoneSpotterPairingServer.swift`: local Wi-Fi QR pairing server and payload handling
- `PhoneSpotterApp/Sources/App/PhoneSpotterSettingsStore.swift`: local `Application Support` persistence
- `PhoneSpotterApp/Sources/App/PhoneSpotterStatusBarController.swift`: status item, popover panel, and menu actions
- `PhoneSpotterApp/Sources/Views/PhoneSpotterMenuBarView.swift`: compact menu bar UI
- `PhoneSpotterApp/Tests/PhoneSpotterTests.swift`: state and platform behavior coverage

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_phone_spotter.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_phone_spotter.sh --workspace /path/to/phone-spotter <command>`
- `generate` uses `xcodegen`.
- `open` launches `PhoneSpotter.xcodeproj`.
- `build` and `test` use `xcodebuild` with a local `.build-debug` derived-data folder.
- `run` builds and opens `PhoneSpotter.app` from `.build-debug/Build/Products/Debug`.

## Constraints

- Keep the app focused on the user's own phone or authorized-device recovery only.
- Preserve explicit Apple or Google provider handoff instead of inventing unsupported remote-control APIs.
- Keep phone state local in `Application Support`; do not add cloud sync or covert telemetry by default.
- Preserve the compact menu bar panel plus settings split instead of turning the app into a large dashboard.
