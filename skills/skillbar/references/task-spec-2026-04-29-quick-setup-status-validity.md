# Task Spec: Quick Setup Status Validity

- Scope: tighten the Setup panel's Quick Setup status label without changing install/update wiring, catalog parsing, or setup actions.
- Problem: the Quick Setup trailing status can still read `ready` when SkillBar has a stale or invalid repo selection, which makes the setup surface look complete even though the catalog cannot load.
- Change:
  - derive the Quick Setup trailing status from repo validity before folder readiness
  - keep detected-repo shortcut labels when SkillBar has a better candidate clone
  - add focused model tests for invalid-repo, missing-folder, custom-folder, and detected-candidate states
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
