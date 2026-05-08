# Task Spec: Pinned Menu Bar Detected Repo Recovery

## Problem

SkillBar preserves the pinned menu bar icon even when the current repo selection no longer contains that skill, but the current-icon surfaces only explain that the icon is unavailable. The user has to leave the panel and hunt through Setup or the icon board even when SkillBar has already detected another viable repo clone.

## Scope

- Detect when an unavailable pinned menu bar icon also has a detected repo recovery candidate.
- Add a direct recovery action to the current menu bar icon panel and the Setup menu bar icons panel.
- Reuse the existing quick-setup path so the repo switch and installs-folder creation stay consistent.
- Add a focused model regression test for the new recovery state.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
