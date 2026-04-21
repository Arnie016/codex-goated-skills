# Reader Mode Bridge SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the deterministic local cleanup helper.

## What it is

- Turn messy reading input into a cleaner handoff in one stop.
- A quiet reader bridge for saved pages, PDFs, copied text, and front-tab metadata.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Intake: Bring in clipboard text, saved HTML, markdown, text files, or a PDF excerpt and show one source card instead of another browser-sized view.
- Cleanup: Surface title, source, cleanup notes, and reading length so the user can confirm the handoff before exporting it.
- Output: Offer markdown, prompt, plain-text, and copy actions because the point is to move the reading onward quickly.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- The skill market will surface the package metadata, while this folder keeps the SwiftUI shape close by.
