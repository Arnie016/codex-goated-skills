# Deck Export Bundle SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Package the deck, notes, and share files before the meeting starts.
- A compact export lane for polished slide handoffs from the menu bar.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Bundle source: Show the current deck, last export time, and destination lane as one compact source card before anything is packaged.
- Handoff pack: Lead with one export bundle action, then offer copy notes, reveal package, and share-ready file checks without sending the user into Finder.
- Why it helps: It removes the repeated Keynote-to-Finder-to-chat loop that happens right before a review, client send, or live presentation.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- The skill market will surface the package metadata, while this folder keeps the SwiftUI shape close by.
