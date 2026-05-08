## Task Spec: Setup Quick Actions

- Scope: tighten the full SkillBar setup section without changing install, update, or catalog plumbing.
- Problem: the Settings view still hides the most common setup recovery actions behind generic "Choose" controls even when SkillBar already knows the next likely step.
- Change:
  - add a compact quick-setup strip to the Setup section
  - surface one-tap detected-repo adoption when another clean clone is available
  - surface direct installs-folder create/open, default-path reset, and folder switching controls
  - keep the existing model actions and CLI delegation unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
