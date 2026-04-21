# Impeccable CLI SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the Impeccable CLI skill package.

## What it is

- A compact scan launcher for local paths or live URLs.
- A small results panel that keeps the target, issue buckets, and next fix visible.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Target switcher: move between repo path scans and live URL checks without changing the mental model.
- Findings summary: show issue counts, severity, and the next high-signal fix instead of dumping raw output first.
- Output actions: keep one-click affordances for rerun, copy JSON, and open command help.

## Notes

- Drop these files into a macOS SwiftUI target if you want a status-item shell around `impeccable detect`.
- The prototype is intentionally narrow: launch a scan, inspect findings, and move back to the code.
