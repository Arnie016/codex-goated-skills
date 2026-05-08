# SkillBar Setup And Pack Recovery Options

Date: 2026-05-06

## Goal

Reduce action sprawl in the SkillBar setup and pack recovery surfaces without hiding the primary path.

## Scope

- Keep setup row primary actions direct.
- Move secondary setup row actions such as open, reveal, and shortcut adoption behind explicit options menus.
- Keep pack recovery's detected-repo adoption action direct.
- Move detected-repo open/reveal and current-repo inspection into one compact pack recovery options menu.
- Add focused view helper tests for the new menu labels.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
