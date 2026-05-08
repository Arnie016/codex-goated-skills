# Task Spec: Repo And Website Launch Manifests

## Goal

Add first-class manifest metadata for the existing `repo-launch` and `website-drop` skills so SkillBar can surface the launch pack's core repository and web deployment workflows without falling back to `SKILL.md` frontmatter alone.

## Scope

- Add `skills/repo-launch/manifest.json`.
- Add `skills/website-drop/manifest.json`.
- Preserve existing `SKILL.md`, `agents/openai.yaml`, SVG assets, and pack membership.
- Regenerate and verify the generated catalog after metadata changes.

## Guardrails

- Do not create a new skill.
- Keep the primary team as Launch And Distribution from `collections/SKILL_TEAMS.md`.
- Closest existing skills are `brand-kit` and `content-pack`; this pass is materially different because it covers repo structure and deploy readiness rather than identity or launch copy.
- Keep metadata local-first and explicit about account, token, environment-variable, or deploy handoff boundaries.
