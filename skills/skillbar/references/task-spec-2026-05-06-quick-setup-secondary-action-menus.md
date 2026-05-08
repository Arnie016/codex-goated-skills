# Quick Setup Secondary Action Menus

## Problem

Quick Setup still presents folder and repo inspection actions as peer buttons beside the main setup action. This makes the fastest path less obvious in the compact menu-bar surface, especially when a detected repo and custom installs folder are both present.

## Scope

- Keep the direct Quick Setup action prominent when SkillBar can adopt or confirm a repo.
- Keep a direct Create Folder action only when there is no repo setup action already doing that work.
- Move secondary folder actions such as Open, Reveal, Use Default, and Choose Folder into a Folder Options menu.
- Move secondary detected/current repo inspection actions into a Repo Options menu while keeping Choose Repo direct.
- Cover the menu labels and direct-create visibility rules with small view helper tests.

## Verification

- `bash scripts/run_skillbar.sh typecheck`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `bash scripts/run_skillbar.sh smoke-install skillbar`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
- `bash scripts/run_skillbar.sh test` when the current runner environment permits it.
