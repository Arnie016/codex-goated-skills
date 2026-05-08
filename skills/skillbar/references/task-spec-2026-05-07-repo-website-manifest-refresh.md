# Repo And Website Launch Manifest Refresh

Date: 2026-05-07

## Goal

Promote the existing `repo-launch` and `website-drop` skills from fallback catalog metadata to manifest-owned SkillBar metadata.

## Scope

- Keep both skills in the `Launch And Distribution` team from `collections/SKILL_TEAMS.md`.
- Preserve their existing `SKILL.md`, `agents/openai.yaml`, assets, references, and `launch-and-distribution` pack membership.
- Refresh generated catalog output so SkillBar surfaces their manifest-owned detail copy, docs paths, icon paths, and `system_symbol` values.

## Non-Goals

- Do not create a new skill.
- Do not change install or update behavior.
- Do not touch Swift app source for this metadata-only pass.

## Product Notes

- Closest pair: `repo-launch` and `website-drop`.
- Difference: `repo-launch` polishes a rough project into a GitHub-ready repository; `website-drop` audits a web app and selects the simplest deploy path.
- Safety posture: both workflows stay local-first, use explicit user-selected project inputs, and avoid hidden account, registry, or token persistence.
