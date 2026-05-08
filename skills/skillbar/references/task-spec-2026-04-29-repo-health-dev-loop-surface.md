## Task

Expose SkillBar's existing `codex-goated develop` action in the Setup repo-health panel so the local maintenance loop is visible alongside catalog check and audit.

## Why

- The model and CLI already support the development loop, but the current UI hides it.
- Repo-health actions should be direct from the menu bar without requiring shell fallback.
- This is a narrow UX improvement that fits the existing compact Setup surface.

## Scope

- Add a `Dev Loop` button and help text in the SkillBar Setup repo-health section.
- Add a model test that verifies the action dispatches `SkillCommandAction.develop`.
- Do not change CLI semantics, install/update flows, or broader layout.
