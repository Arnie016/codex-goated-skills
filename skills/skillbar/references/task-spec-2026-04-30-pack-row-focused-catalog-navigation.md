# Task Spec: Pack Row Focused Catalog Navigation

## Problem

SkillBar already lets a pack row switch the app into a pack-scoped catalog view, but the active pack row does not make that state obvious. The current row also leaves the user without a direct "go there again" affordance once the pack is already focused, which makes pack browsing feel indirect.

## Scope

- Keep the existing pack focus model and browse behavior.
- Add a compact active-state affordance on the currently focused pack row.
- Replace the ambiguous row-level browse button with a direct catalog navigation label when that row is already the active pack focus.
- Preserve the existing recovery path for broken packs and the existing install/update actions.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
