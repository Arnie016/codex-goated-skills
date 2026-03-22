# VibeWidget

Native macOS SwiftUI app plus WidgetKit extension for voice-first vibe control:

- Apple Home lights and scenes
- Spotify vibe playback and discovery
- PartyBox-aware output status
- Compact AI command panel

## Open The Project

1. Make sure Xcode's license has been accepted on this Mac:
   `sudo xcodebuild -license`
2. Open `VibeWidget.xcodeproj` in Xcode.
3. If needed, set the active developer directory to Xcode:
   `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`

## Before First Run

- Keep your OpenAI key in Keychain under the default service name `OPENAI_API_KEY`.
- Add your Spotify app client ID during onboarding.
- Grant microphone, speech recognition, Apple Home, and automation permissions when prompted.

## Main Targets

- `VibeWidget`: macOS SwiftUI app
- `VibeWidgetWidget`: WidgetKit extension
- `VibeWidgetCore`: shared models, storage, and parser logic

## Verification Status

- `xcodegen generate` succeeded for the local project scaffold
- shared core, app sources, and widget sources made it through local compiler type-check passes
- full `xcodebuild` and XCTest runs are still blocked on machines where the Xcode license has not been accepted

## Notes

- The app stays Apple-only for Bluetooth flow, so speaker pairing and output switching use native macOS handoff instead of private automation.
- The workspace includes a CLT-safe HomeKit fallback so source type-checks can still run before full Xcode activation.
