# VibeWidget / VibeBluetooth Project Map

Default workspace: use `apps/vibe-widget` when working inside this repository. Otherwise pass `--workspace /path/to/vibe-widget` to the runner.

## Targets

- `VibeWidget`: macOS SwiftUI app
- `VibeWidgetWidget`: WidgetKit extension with App Intents
- `VibeWidgetCore`: shared models, parser, keychain, and app-group state

## Main Files

- `project.yml`: XcodeGen spec
- `VibeWidgetApp/Sources/App/AppModel.swift`: shared app state and action orchestration
- `VibeWidgetApp/Sources/Services/`: HomeKit, Spotify, voice capture, permissions, audio route, AI command planning
- `VibeWidgetApp/Sources/Views/`: onboarding, dashboard, and AI panel
- `VibeWidgetWidget/Sources/`: widget timeline and quick intents
- `VibeWidgetCore/Sources/`: shared models and app-group storage
- `VibeWidgetCore/Tests/ContextLibraryTests.swift`: deterministic coverage for token estimation and chunk sizing
- `VibeWidgetCore/Tests/FallbackIntentParserTests.swift`: deterministic coverage for the fallback command parser

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_vibe_bluetooth.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_vibe_bluetooth.sh --workspace /path/to/vibe-widget <command>`
- `inspect` prints the key app, widget, core, and test files for quick orientation.
- `generate` uses `xcodegen`.
- `open` launches `VibeWidget.xcodeproj`.
- `typecheck` uses the local SDK, a temporary core module, and a workspace-local module cache for a lightweight sanity pass.
- `test` runs the `VibeWidgetCoreTests` bundle with `xcodebuild test` and unsigned local validation.
- `build` uses the workspace-local `.build-debug` folder and unsigned local validation so it stays usable without a development certificate, while still requiring full Xcode.

## Constraints

- Keep the app Apple-only for Bluetooth and output routing.
- HomeKit direct control is allowed, but pairing/connect automation is not.
- OpenAI and Spotify credentials stay in Keychain.
