# TeleBar Project Map

Default workspace: use `apps/telebar` when working inside this repository. Otherwise pass `--workspace /path/to/telebar` to the runner.

## Target

- `TeleBar`: macOS SwiftUI menu bar app with `LSUIElement` enabled

## Main Files

- `project.yml`: XcodeGen spec
- `TeleBarApp/Info.plist`: menu-bar-only app metadata
- `TeleBarApp/Sources/App/TeleBarApp.swift`: `MenuBarExtra` entry point
- `TeleBarApp/Sources/App/TeleBarModel.swift`: app state, keychain-backed secrets, Telegram + AI actions
- `TeleBarApp/Sources/Models/TelegramModels.swift`: chat, thread, and bot models
- `TeleBarApp/Sources/Services/TelegramService.swift`: `getMe`, `getUpdates`, and `sendMessage`
- `TeleBarApp/Sources/Services/OpenAIService.swift`: summaries and draft replies
- `TeleBarApp/Sources/Services/KeychainStore.swift`: local token storage
- `TeleBarApp/Sources/Views/MenuBarView.swift`: compact grouped macOS popover UI

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_telebar.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_telebar.sh --workspace /path/to/telebar <command>`
- `generate` uses `xcodegen`.
- `open` launches `TeleBar.xcodeproj`.
- `build` uses `xcodebuild` with a local derived-data folder.
- `run` builds and opens `TeleBar.app` from `.build-debug/Build/Products/Debug`.

## Constraints

- Keep the app menu-bar-only and compact.
- Prefer grouped rows and hover help over larger custom dashboard patterns.
- Telegram bot tokens and OpenAI keys stay in Keychain only.
- Inbox data must reflect only what the bot can actually access.
- Group, channel, inline, and attach flows should use Telegram-supported links and BotFather.
