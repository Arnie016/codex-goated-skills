# Reply Queue Bar SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Turn copied comments and inbox snippets into one calm local response lane.
- A Mac menu-bar queue for triaging replies, keeping the next answer visible, and handing a ready draft forward.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Queue snapshot: Keep open counts and the next actionable reply visible before the user reopens another app.
- Bucket switcher: Let the user pivot between urgent, reusable, and archive buckets without leaving the compact menu-bar frame.
- Draft handoff: Keep one response draft, copy action, and archive step close to the current item so the reply leaves cleanly.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app shell.
- Pair the UI with `scripts/reply_queue_bar.py` when you want deterministic local queue behavior before wiring app state.
