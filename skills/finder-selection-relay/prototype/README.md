# Finder Selection Relay SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Capture the current Finder selection and hand it off without cleaning paths by hand.
- Fall back to explicit local paths when Finder automation is unavailable or the paths are already known.
- A quiet menu-bar relay for files, folders, shell-safe paths, and prompt-ready context.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Selection summary: Show the current Finder selection or explicit path batch as one small summary card with item count, common location, and safe metadata lanes.
- Format shortcuts: Offer one-tap output shapes for prompt context, markdown, shell-safe paths, and ticket bullets.
- Mac feel: Keep the panel narrow, calm, and menu-bar first with a recent selection strip instead of a Finder replacement dashboard.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- The skill market will surface the package metadata, while this folder keeps the SwiftUI shape close by.
