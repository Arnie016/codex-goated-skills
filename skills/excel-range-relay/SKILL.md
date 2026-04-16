---
name: excel-range-relay
description: A menu-bar Excel relay for turning the copied sheet selection into clean markdown, CSV, JSON, or prompt context without rebuilding the table by hand.
---

# Excel Range Relay

Use this skill when the user wants a Mac menu-bar utility for taking the current Excel selection and handing it off into prompts, docs, tickets, or chat without reformatting the table by hand.

## Core Workflow

- Reads the copied Excel selection from the clipboard and preserves the table shape for markdown, CSV, JSON, or prompt-ready output.
- Uses lightweight macOS automation only for workbook, sheet, and range labels when Microsoft Excel is frontmost.
- Shows one compact preview card with workbook, sheet, range, row count, and the next output presets.
- Prefers handoff formats that are already useful in the next destination: markdown table, CSV, JSON, or prompt context.
- Treats the surface as a relay step, not a spreadsheet editor or workbook manager.

## Local Helper

Use `scripts/excel_range_relay.py` when a deterministic local handoff is useful:

```bash
python skills/excel-range-relay/scripts/excel_range_relay.py current --format json
python skills/excel-range-relay/scripts/excel_range_relay.py current --format markdown
python skills/excel-range-relay/scripts/excel_range_relay.py copy --format prompt
python skills/excel-range-relay/scripts/excel_range_relay.py copy --format csv
cat selection.tsv | python skills/excel-range-relay/scripts/excel_range_relay.py current --stdin --format prompt
```

The helper reads the current clipboard with `pbpaste`, preserves tabular structure, and tries to label the payload with workbook, sheet, and range metadata when Microsoft Excel is frontmost. It does not use any cloud APIs or network access.

## Guardrails

- Do not claim live workbook sync, background watchers, or Microsoft 365 cloud state; this skill is about explicit clipboard handoff plus lightweight front-app metadata only.
- If Excel is not frontmost or automation permission is blocked, keep the handoff working from clipboard contents and explain that labels may be missing.
- Keep the primary action obvious and the popover short; do not turn this into a spreadsheet browser or formula editor.

## Prototype

- SwiftUI starter files live in `prototype/`.
- The prototype sketches a menu-bar shell with a clipboard snapshot, table preview, preset outputs, and one primary copy action.

## When extending

- Add export depth only when it improves the handoff itself.
- If the skill grows, keep the menu-bar path short and the preview readable at a glance.
