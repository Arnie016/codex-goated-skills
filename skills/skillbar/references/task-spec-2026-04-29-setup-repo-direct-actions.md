## Task Spec: Setup Repo Direct Actions

- Scope: tighten the Setup quick-actions strip so repo-path recovery is as direct as installs-folder recovery.
- Problem: Setup already surfaces fast folder actions, but repo switching and repo inspection still hide below in generic settings rows even when SkillBar already knows the current repo state.
- Change:
  - keep the existing quick-setup repo-adoption shortcut when another detected clone exists
  - add direct repo buttons for choosing a repo and opening or revealing the active repo
  - keep catalog parsing, install/update plumbing, and repo-selection logic unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
