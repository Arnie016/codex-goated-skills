# Package Hygiene Audit SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Catch the missing packaging pieces before the release leaves your Mac.
- A menu-bar audit lane for app bundles, notes, screenshots, and ship files.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Audit pass: Show the current release folder as one checklist card with bundle, archive, screenshots, and notes already grouped by ship readiness.
- Why it helps: It removes the repeated Finder-to-browser-to-notes loop that happens right before a release when attention is already fragmented.
- UI direction: Use a compact status stack with one blocking issue state, one ready-to-ship state, and a short action row for reveal, copy, and export.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- Run `python3 ../scripts/package_hygiene_audit.py audit --release-dir /path/to/release` first when you want deterministic local data to drive the prototype.
- The skill market will surface the package metadata, while this folder keeps the SwiftUI shape close by.
