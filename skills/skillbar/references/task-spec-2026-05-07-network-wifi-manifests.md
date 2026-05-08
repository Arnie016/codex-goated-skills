# Network And WiFi Manifest Pass

## Goal

Move two high-surface macOS network skills onto manifest-owned metadata so SkillBar and the generated catalog can show clear names, local-first boundaries, icons, and fallback symbols without relying only on `agents/openai.yaml` plus `SKILL.md` frontmatter.

## Scope

- Add `manifest.json` for `network-studio`.
- Add `manifest.json` for `wifi-watchtower`.
- Preserve the current product split:
  - `network-studio` owns the portable LAN monitor workspace and optional SwiftBar wrapper.
  - `wifi-watchtower` owns the native menu-bar app for Wi-Fi trust scoring.
- Regenerate and verify the catalog.

## Non-Goals

- No new skill creation.
- No app source, runner, signing, or installer changes.
- No network behavior changes.
