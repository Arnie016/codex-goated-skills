# Task Spec: Catalog Row Pinned Install Recovery

## Problem

SkillBar exposes a compact icon action on catalog rows, but the current state logic treats any pinned row as a reset candidate. If a skill is still pinned in the menu bar while its installed folder is missing, the catalog row shows `Use Default` instead of the direct recovery action the user actually needs.

## Scope

- Keep `Use Default` for skills that are both pinned and currently installed.
- Treat pinned-but-uninstalled skills as an `Install + Pin` recovery path in catalog rows.
- Add or update focused model tests so the row accessory logic matches the existing icon detail behavior.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
