# Task Spec: Pinned Menu Bar Secondary Actions Menu

## Problem

The current pinned menu bar control strip exposes the primary recovery action plus `Open`, `Reveal`, and `Use Default` as sibling buttons. When the pinned icon is stale, that row becomes crowded and pushes the real next step behind too many equal-weight controls.

## Scope

- Keep the primary pinned-icon recovery action direct and prominent.
- Move the secondary detected-repo inspection actions into a compact repo options menu.
- Reuse the existing repo recovery commands and copy instead of adding new behavior.
- Add a focused view regression test for the new menu label helper.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `bash scripts/run_skillbar.sh smoke-install skillbar`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
