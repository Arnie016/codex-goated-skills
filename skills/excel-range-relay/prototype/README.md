# Excel Range Relay SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Turn a copied Excel range into prompt-ready context in one step.
- A calm menu-bar relay for spreadsheet selections, markdown tables, and quick handoffs.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`
- `../scripts/excel_range_relay.py`

## Prototype sections

- Clipboard intake: Read the copied Excel selection as structured rows, then attach workbook, sheet, and range labels when Excel is the active app.
- Format presets: Offer markdown table, CSV, JSON, and prompt-context outputs so the same range can move cleanly into chat, docs, or tickets.
- Handoff flow: Lead with one preview card, one primary copy action, and a small preset row so the popover feels like a relay, not a spreadsheet clone.

## Notes

- The SwiftUI shell mirrors the local helper: clipboard snapshot, table preview, and copy-ready presets.
- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- Use the helper script when you want a deterministic local path before wiring real app state.
