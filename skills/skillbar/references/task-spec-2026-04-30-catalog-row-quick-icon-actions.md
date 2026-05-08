# Task Spec: Catalog Row Quick Icon Actions

## Problem

SkillBar makes install and update actions obvious in the main catalog rows, but pinning a skill icon to the menu bar still requires a detour into the Icons section. That makes a common action feel indirect even though the model already knows how to pin, reset, and install-plus-pin.

## Scope

- Add one compact row-level icon action for catalog skill rows.
- Keep the existing install or update button as the primary package action.
- Use the row action to pin installed skills, install and pin uninstalled skills, or reset the menu bar icon when the row is already pinned.
- Preserve the existing detailed icon board workflow.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
