# Cursor Studio Manifest Pass

## Goal

Give the existing `cursor-studio` skill first-class manifest metadata so SkillBar and the generated catalog stop relying on inferred frontmatter and OpenAI YAML for its product surface.

## Scope

- Add `skills/cursor-studio/manifest.json`.
- Preserve the existing Cursor Studio skill boundary, icons, default prompt, and pack membership.
- Regenerate the catalog and run the required catalog, audit, and SkillBar checks.

## Non-Goals

- Do not change Cursor Studio app source, project files, signing files, or runner behavior.
- Do not create a new skill or split Cursor Studio from its current packs.
