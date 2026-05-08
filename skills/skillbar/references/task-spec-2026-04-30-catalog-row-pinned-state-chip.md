# Task Spec: Catalog Row Pinned State Chip

## Problem

SkillBar now supports pinning directly from catalog rows, but the main skill list still does not visibly identify which row owns the current menu bar icon. That forces users to cross-check the separate icon panel just to confirm what is pinned.

## Scope

- Add a compact pinned-state badge to live catalog rows for the current menu bar selection.
- Keep the existing install, update, and row accessory actions unchanged.
- Preserve the more detailed pinned-icon controls in the Icons and Setup sections.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
