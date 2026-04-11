# Patch Pilot SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Turn a diff into the next safe move.
- A menu-bar patch triage panel for fix briefs, risk notes, and the next safe command.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Input: Paste a diff, a staged file list, or a review thread and collapse it into one working brief.
- Decision support: Lead with touched areas, likely regressions, and the single next command so the user can act without bouncing between tools.
- Mac feel: Use a slim menu-bar popover with one primary recommendation, a compact risk stack, and a copyable reply block.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- The skill market will surface the package metadata, while this folder keeps the SwiftUI shape close by.
