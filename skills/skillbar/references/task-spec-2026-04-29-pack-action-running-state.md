## Task Spec: Pack Action Running State

- Scope: tighten SkillBar's pack install/update feedback without changing command wiring, pack parsing, or repo-health flows.
- Problem: SkillBar already tracks the active pack command, but the Packs UI only shows a generic app-level busy state, so pack installs and updates can feel stuck or ambiguous after the user clicks.
- Change:
  - surface pack-level running state directly in each pack row
  - swap install and update button labels to active verbs while the selected pack command is running
  - reuse the existing inline progress label treatment so pack actions match skill action feedback
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
