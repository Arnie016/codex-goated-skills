---
name: clipboard-studio
description: Shape, build, or refine a Clipboard Studio workflow or macOS menu bar app that turns copy and paste into searchable history, pinned snippets, smart transforms, and quick paste actions. Use when Codex needs to design or implement a clipboard-focused utility, keep the panel compact, or wire local pasteboard actions without leaking sensitive data.
---

# Clipboard Studio

Use this skill when the user wants copy and paste "on steroids" as a focused tool, especially for macOS menu bar workflows, snippet launchers, or clipboard-heavy productivity flows.

## Quick Start

1. Decide first whether the request is product shaping, a new workspace scaffold, or changes to an existing clipboard app.
2. Keep the main loop fast: capture, search, transform, and paste.
3. Default to local-first storage and explicit privacy boundaries.
4. Make the menu bar surface compact and action-first.
5. If a workspace already exists, inspect the pasteboard model, history retention, hotkeys, and quick-paste actions before editing.

## Workflow

### Product Boundary

- Clipboard Studio owns:
  - clipboard history
  - pinned snippets and reusable slots
  - quick paste actions
  - paste transforms such as plain text, cleanup, slugify, or case conversion
  - app-aware or context-aware snippet recall
- Keep it focused on copy and paste speed. Do not bloat it into notes, docs, or a full knowledge base.

### UX Guidance

- The first screen should answer:
  - what was copied most recently
  - what is pinned
  - what can be pasted next
- Prefer search, keyboard-first actions, and one-tap paste over deep settings.
- Use compact previews that make text, links, code, and file paths easy to scan.
- If transformations exist, show the transformed result before overwriting the clipboard.

### Privacy And Safety

- Treat clipboard contents as sensitive by default.
- Avoid persisting likely secrets, tokens, passwords, or one-time codes unless the user explicitly asks for that behavior.
- Prefer local-only storage unless the user asks for sync.
- Make it obvious when the app is reading, pinning, pausing, or clearing clipboard history.

### Editing Guidance

- Keep data models deterministic:
  - history item
  - pinned snippet
  - transform preset
  - quick action or hotkey
- Separate pasteboard polling, persistence, and panel state so each piece can be tested cleanly.
- If the app supports quick paste into other apps, fail gracefully when permissions are missing.
- Preserve responsive menu bar behavior: fast launch, minimal scrolling, and clear empty states.

### Required Deliverables

- A clear clipboard capture and retrieval loop.
- One obvious "paste now" or "copy transformed result" action.
- Safe handling rules for sensitive clipboard content.
- A compact icon and visual direction that reads as fast duplication, transfer, and control.

## Resources

- `agents/openai.yaml`: UI metadata and default invocation prompt.
- `assets/`: branded icons for repo listings and skill chips.
- `references/workflow-map.md`: product boundary, icon language, panel structure, and safe-default clipboard rules.
