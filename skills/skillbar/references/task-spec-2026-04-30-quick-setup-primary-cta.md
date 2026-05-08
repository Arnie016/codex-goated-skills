# Task Spec: Quick Setup Primary CTA

## Goal

Make the primary Quick Setup action in SkillBar read like the next step, not like a folder label.

## Scope

- Add explicit primary CTA copy in the SkillBar model for:
  - the current repo already being selected
  - a different detected repo being available
- Use that copy in the Setup panel's Quick Setup button.
- Add unit coverage for both label states.

## Guardrails

- Keep the change local to `apps/skillbar` plus the paired task spec.
- Do not change install/update command behavior.
- Do not alter repo selection logic or candidate discovery.
