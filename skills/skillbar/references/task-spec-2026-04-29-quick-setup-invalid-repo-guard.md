## Task Spec: Quick Setup Invalid Repo Guard

- Scope: tighten the quick-setup action when SkillBar only knows an invalid current repo path; do not change install/update command wiring or catalog parsing.
- Problem: `Complete Quick Setup` can currently keep an invalid repo selection, create the installs folder anyway, and leave setup without a clear repo-blocked status.
- Change:
  - stop the quick-setup action early when the chosen repo path still does not resolve to a valid local clone
  - keep Setup selected and show direct repo-recovery copy instead of silently continuing
  - cover the guard with a focused `SkillBarModel` test
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
