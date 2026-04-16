# Context Assembly Workflow Map

Default workspace: if the current repo contains `apps/clipboard-studio/project.yml`, use `apps/clipboard-studio`. Otherwise, treat the request as product shaping or a new macOS context-assembly utility. Read `workspace-map.md` when the request is about the bundled app workspace.

## Core Jobs

- capture selected context quickly
- assemble code, logs, notes, and links into one result
- search recent history without friction
- pin reusable snippets and slots
- send or export the assembled result from a compact menu bar panel

## Product Contract

- Context Assembly should make cross-app copy and paste feel faster, safer, and easier to control.
- The core loop is:
  - capture or observe text
  - preview and assemble the important parts
  - let the user search, pin, send, or export it
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
  - info or quick-help surface
  - shortcut summary
  - pause or private toggle
- Current assembly:
  - one clear objective field
  - newest captures first
  - one-tap send, copy, and export actions
- Recent history:
  - newest items first
  - compact previews
  - one-tap add, copy, paste, and pin actions

## Icon Language

- Use a restrained clipboard or list metaphor that still reads clearly at menu bar size.
- Add one subtle readiness cue rather than multiple decorative states.
- Keep the silhouette legible at tiny sizes.
- Favor one bright accent on a dark base instead of a crowded multicolor mark.

## Validation

- Prefer `scripts/run_clipboard_studio.sh` for `doctor`, `inspect`, `generate`, `build`, `test`, and `run`.
- History ordering should stay newest-first and deterministic.
- Dedup or retention rules should be explicit and testable.
- Export should be deterministic and remember its Markdown folder once chosen.
- Pin, unpin, and reorder behavior should remain stable across relaunches.
