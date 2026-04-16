# Cursor Studio Project Map

Default workspace: use the current repo when it contains `CursorStudioApp` and `project.yml`. Otherwise, pass `--workspace /path/to/workspace` to the runner.

## Targets

- `CursorStudio`: macOS menu bar app for planning custom cursor packs
- `CursorStudioTests`: unit tests for slot selection and brief export
- `FolderStudio`: separate app target for folder skins

## Main Files

- `project.yml`: XcodeGen spec with separate `CursorStudio` and `FolderStudio` targets
- `CursorStudioApp/Sources/App/CursorStudioAppModel.swift`: panel state, export actions, and settings persistence
- `CursorStudioApp/Sources/App/CursorStudioModels.swift`: cursor presets, accent palettes, slot roles, and brief builders
- `CursorStudioApp/Sources/App/CursorStudioStatusBarController.swift`: persistent menu bar panel controller
- `CursorStudioApp/Sources/Views/CursorStudioMenuBarView.swift`: compact menu bar UI
- `CursorStudioApp/Sources/Views/CursorStudioTheme.swift`: shared panel styling
- `CursorStudioApp/Tests/CursorStudioTests.swift`: slot and export regression tests

## Product Contract

- Cursor Studio should produce:
  - a clear prompt template
  - an exact slot list
  - hotspot notes
  - markdown or json export
- Supported slot roles include:
  - starter pack defaults
  - extended roles for full packs
  - exact custom selection
- The app should stay review-first and export deterministic briefs rather than pretending to generate live cursor art when no generator is wired in.

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_cursor_studio.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_cursor_studio.sh --workspace /path/to/workspace <command>`
- `generate` uses `xcodegen`
- `open` launches the workspace's detected `.xcodeproj` file
- `build` and `test` use the `CursorStudio` scheme on macOS

## Constraints

- Keep Cursor Studio separate from Folder Studio in both naming and workflow.
- Do not hide critical export details behind long scrolling panels.
- Preserve exact hotspot notes per selected cursor role.
- If slot metadata changes, update both the builder and the tests together.
