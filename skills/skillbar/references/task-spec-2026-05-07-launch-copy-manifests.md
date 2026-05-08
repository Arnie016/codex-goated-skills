# Task Spec: Launch Copy Manifests

## Goal

Add first-class manifest metadata for the existing `brand-kit` and `content-pack` skills so SkillBar can surface their launch/distribution role, icons, docs, and action copy from structured metadata instead of frontmatter fallback alone.

## Scope

- Add `skills/brand-kit/manifest.json`.
- Add `skills/content-pack/manifest.json`.
- Regenerate the catalog after metadata changes.
- Run catalog and SkillBar checks that fit manifest/catalog work.

## Guardrails

- Do not create new skills.
- Keep the primary team as Launch And Distribution from `collections/SKILL_TEAMS.md`.
- Preserve existing `SKILL.md`, `agents/openai.yaml`, pack membership, and SVG assets.
- Keep metadata local-first, paste-ready, and scoped to launch copy/identity work without adding remote marketplace or account-token behavior.
