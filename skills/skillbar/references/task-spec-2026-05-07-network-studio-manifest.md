# Network Studio Manifest Pass

## Goal

Give the existing `network-studio` skill first-class manifest metadata so SkillBar and the generated catalog can show its portable LAN-monitoring workflow, icons, safety boundary, and docs paths without relying only on `SKILL.md` frontmatter and `agents/openai.yaml`.

## Scope

- Add `skills/network-studio/manifest.json` using the existing small and large SVG assets.
- Preserve current pack membership in `collections/utility-builder-stack.txt`, `collections/productivity-and-workflow.txt`, and `collections/daily-briefs-and-reference.txt`.
- Keep `network-studio` owned by the `macOS System And Device Utilities` team from `collections/SKILL_TEAMS.md`.
- Name the closest existing skill: `wifi-watchtower`. `network-studio` is materially different because it installs a portable workspace and SwiftBar dashboard for LAN presence monitoring, while `wifi-watchtower` is a native macOS app for current Wi-Fi trust scoring.

## Non-Goals

- Do not change Network Studio installer behavior, workspace scripts, or SwiftBar output.
- Do not create a new skill.
- Do not add network calls, account access, or broader persistence.

## Verification

- Validate the new manifest JSON.
- Regenerate `catalog/index.json`.
- Run the required catalog and SkillBar integrity checks.
