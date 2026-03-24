# Folder Studio Project Map

Default workspace: use the current repo when it contains `FolderStudioApp` and `project.yml`. Otherwise, pass `--workspace /path/to/workspace` to the runner.

## Targets

- `FolderStudio`: macOS menu bar app for context-aware folder skins
- `FolderStudioTests`: unit tests for folder analysis and brief generation
- `CursorStudio`: separate app target for cursor-pack planning

## Main Files

- `project.yml`: XcodeGen spec with separate `FolderStudio` and `CursorStudio` targets
- `FolderStudioApp/Sources/App/CursorStudioAppModel.swift`: staged folder state, preview refresh, and apply/reset actions
- `FolderStudioApp/Sources/App/CursorStudioModels.swift`: folder categories, engravings, palettes, and brief builders
- `FolderStudioApp/Sources/Services/FolderContextAnalyzer.swift`: folder inspection and dominant-category heuristics
- `FolderStudioApp/Sources/Services/FolderIconRenderer.swift`: Finder-style custom icon rendering
- `FolderStudioApp/Sources/App/CursorStudioStatusBarController.swift`: persistent menu bar panel controller
- `FolderStudioApp/Sources/Views/CursorStudioMenuBarView.swift`: compact menu bar workflow and controls
- `FolderStudioApp/Sources/Views/CursorStudioTheme.swift`: shared panel styling
- `FolderStudioApp/Tests/CursorStudioTests.swift`: folder analysis and brief regression tests

## Product Contract

- Folder Studio should:
  - inspect a folder and derive a dominant content category
  - suggest engraving and badge direction
  - render a native-feeling Finder-style folder icon
  - let the user apply or reset the icon in Finder
- High-signal metrics should remain visible:
  - total items
  - docs
  - code
  - images
  - media
  - subfolders

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_folder_studio.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_folder_studio.sh --workspace /path/to/workspace <command>`
- `generate` uses `xcodegen`
- `open` launches `VibeWidget.xcodeproj`
- `build` and `test` use the `FolderStudio` scheme on macOS

## Constraints

- Keep Folder Studio separate from Cursor Studio in both naming and workflow.
- Preserve native Finder icon application and reset behavior.
- Keep the panel compact and avoid turning the analysis surface into a long-scrolling dashboard.
- If category heuristics or icon rendering change, update the tests together.
