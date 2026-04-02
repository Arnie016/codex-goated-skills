# Minecraft Skin Bar Project Map

Default workspace: use `apps/minecraft-skinbar` when working inside this repository. Otherwise pass `--workspace /path/to/minecraft-skinbar` to the runner.

## Target

- `MinecraftSkinBar`: macOS SwiftUI app with a `MenuBarExtra` primary surface

## Main Files

- `project.yml`: XcodeGen spec for the app target
- `MinecraftSkinBarApp/Info.plist`: app metadata
- `MinecraftSkinBarApp/Sources/App/MinecraftSkinBarApp.swift`: app entry point and settings scene
- `MinecraftSkinBarApp/Sources/App/SkinBarModel.swift`: prompt state, latest file tracking, launcher actions, and API key handling
- `MinecraftSkinBarApp/Sources/Services/SkinStudioCLI.swift`: bridges the app to `minecraft_skin_studio.py` through `uv`
- `MinecraftSkinBarApp/Sources/Services/KeychainStore.swift`: local keychain storage for the API key
- `MinecraftSkinBarApp/Sources/Views/MenuBarView.swift`: main menu bar UI for prompt, import, preview, and launcher handoff

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_minecraft_skinbar.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_minecraft_skinbar.sh --workspace /path/to/minecraft-skinbar <command>`
- `doctor` reports workspace shape, tool availability, and Xcode readiness without blocking on a missing optional tool.
- `generate` uses `xcodegen`.
- `open` launches `MinecraftSkinBar.xcodeproj`.
- `build` uses `xcodebuild` with a local `.build-debug` derived-data folder.
- `typecheck` runs `bash -n` on the runner and `python3 -m py_compile` on `minecraft_skin_studio.py`.
- `test` runs deterministic helper smoke checks for skin cleanup, preview rendering, and launcher JSON registration.
- `run` builds and opens `MinecraftSkinBar.app` from `.build-debug/Build/Products/Debug`.
- The current project does not define an Xcode unit-test target, so `test` covers the helper contract and `build` is still the strongest app-local validation path.

## Runtime Dependencies

- `scripts/minecraft_skin_studio.py` must be present alongside the skill package.
- `uv` must be installed on the Mac so the app can run the Python helper with Pillow.
- `OPENAI_API_KEY` can come from the environment or the app's keychain-backed field.
- The launcher library lives at `~/Library/Application Support/minecraft/launcher_custom_skins.json`.

## Constraints

- Keep the app focused on local skin creation, preview, and launcher registration.
- Preserve keychain-backed API key storage instead of plaintext files.
- Keep the UI compact and action-oriented rather than turning it into a full editor.
- Do not claim the app can directly manage Mojang account skin sync beyond the local launcher workflow it actually performs.
