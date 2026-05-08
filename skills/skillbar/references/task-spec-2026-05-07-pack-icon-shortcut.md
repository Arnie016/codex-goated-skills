# Pack Icon Shortcut

## Goal

Make pack browsing lead directly to icon picking when that is the user's next action.

## Scope

- Add a SkillBar model action that scopes the catalog to a pack and opens the Icons section.
- Surface a compact `Icons` button on pack rows that have available local members.
- Keep broken packs with no available members in Packs so recovery messaging remains visible.
- Cover the state transition with a focused model test.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
