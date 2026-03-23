---
name: minecraft-skin-studio
description: Draft, clean, preview, and register Minecraft Java player skins from prompts or PNG files. Use when Codex needs to turn a skin idea into a launcher-ready skin sheet, add a custom skin into the local Minecraft Launcher library, render a quick preview image, or help the user iterate on prompt-based Minecraft skins on macOS.
---

# Minecraft Skin Studio

Use this skill when the user wants a Minecraft Java skin workflow, not a server workflow.

## Quick Start

1. Treat the launcher-ready deliverable as a `64x64` skin PNG plus a preview image.
2. Prefer registering skins through the launcher's local custom-skins file instead of brittle UI clicking.
3. If the user has a prompt only, generate a draft skin sheet first, then clean it into a usable `64x64` skin.
4. Be honest that prompt-to-perfect skin generation is still draft-quality and may need a second pass.
5. If the user already has a PNG, skip generation and register it directly.

## Workflow

### Choose The Lane

- Use `go` for the full flow: prompt draft, clean skin, preview, and launcher registration.
- Use `generate` when the user only wants files and iteration.
- Use `register` when they already have a valid skin PNG.
- Use `render-preview` when they want a quick visual check without touching the launcher.

### Skin Rules

- Java launcher skins should be treated as `64x64` PNG files.
- Keep the launcher-facing flow simple:
  - skin PNG
  - preview PNG
  - custom skin entry in `launcher_custom_skins.json`
- If the user asks for direct launcher automation, prefer the local JSON registration path first.
- Do not pretend generic image generation is guaranteed to produce a perfect UV layout on the first try.

### Required Deliverables

- A launcher-ready skin PNG path.
- A preview image path.
- A clear note on whether the skin was registered into the local launcher library.
- If generation was used, a short quality note about whether the result looks usable or needs another pass.

### Editing Guidance

- Keep prompts visual and specific: outfit, palette, theme, face detail, accessories.
- Use `wide` unless the user explicitly wants `slim`.
- Prefer simple names for launcher entries.
- Do not overwrite an existing launcher skin entry unless the user clearly wants a replace/update behavior.

## Resources

- `scripts/minecraft_skin_studio.py`: generate, clean, preview, and register skins.
- `references/launcher-flow.md`: launcher storage path, workflow boundaries, and practical limits.
- `agents/openai.yaml`: UI metadata and default invocation prompt.
