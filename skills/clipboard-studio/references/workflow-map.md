# Clipboard Studio Workflow Map

Default workspace: if the current repo contains `ClipboardStudioApp` and `project.yml`, use it. Otherwise, treat the request as product shaping or a new macOS clipboard utility.

## Core Jobs

- capture new clipboard items quickly
- search recent history without friction
- pin reusable snippets and slots
- transform text before re-copy or paste
- trigger quick paste actions from a compact menu bar panel

## Product Contract

- Clipboard Studio should make copy and paste feel faster, safer, and easier to control.
- The core loop is:
  - detect clipboard change
  - classify and preview the item
  - let the user search, pin, transform, or paste it
- Support common item types clearly:
  - plain text
  - links
  - code snippets
  - file paths
- If richer content types are added later, the compact panel should still degrade gracefully.

## Safe Defaults

- Add a capture pause switch or private mode.
- Avoid storing likely secrets or passwords by default.
- Make clear when history is being cleared or pinned.
- Prefer local persistence unless sync is explicitly requested.

## Panel Structure

- Header:
  - current status
  - search field
  - pause or private toggle
- Recent history:
  - newest items first
  - compact previews
  - one-tap copy, paste, and pin actions
- Transform strip:
  - plain text
  - cleanup
  - case conversion
  - slugify or format helpers
- Pinned section:
  - stable snippets
  - reorder support
  - shortcut-friendly labels

## Icon Language

- Use stacked cards or sheets to signal clipboard history and duplication.
- Add one clear forward-motion cue such as an arrow, streak, or thrust shape to signal paste speed.
- Keep the silhouette legible at tiny sizes.
- Favor one bright accent on a dark base instead of a crowded multicolor mark.

## Validation

- History ordering should stay newest-first and deterministic.
- Dedup or retention rules should be explicit and testable.
- Transform previews should not silently overwrite the clipboard before confirmation.
- Pin, unpin, and reorder behavior should remain stable across relaunches.
