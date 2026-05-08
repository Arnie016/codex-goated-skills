# Task Spec

- Scope: tighten the SkillBar Icons header so its quality signals match the board the user is currently looking at.
- Problem: the Icons header still shows whole-catalog missing-icon and duplicate-name counts as passive chips, which can disagree with the current search or pack-focused icon grid and makes cleanup actions feel indirect again.
- Change:
  - make the Icons header guardrail chips reflect the current icon-board scope
  - turn warm chips into direct shortcuts that select the first visible missing-icon or duplicate-name entry
  - preserve the existing setup-level guardrails as the repo-wide cleanup entry point
  - avoid changing catalog parsing, install/update plumbing, or pack logic
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
