## Task Spec

- Scope: tighten SkillBar's first-run setup path inside the existing menu-bar UI.
- Problem: when SkillBar can already detect a valid repo clone, first-run setup still asks the user to select the repo and prepare the installs folder as separate steps.
- Change:
  - add a one-tap setup action that adopts the strongest detected repo and ensures the installs folder exists
  - surface that action in the no-repo quick-setup strip and the full setup panel
  - keep install, update, and catalog parsing behavior unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
