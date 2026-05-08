## Task Spec: Quick Setup Folder Recovery

- Scope: tighten the no-repo SkillBar setup state so installs-folder recovery is a one-tap action instead of forcing users through the folder picker.
- Why now: the current quick-setup panel shows the installs path but the main button still routes to folder selection even when the common next step is simply creating the missing folder.
- Planned change:
  - keep the existing model and CLI behavior unchanged
  - update the `MenuBarView` quick-setup branch to expose direct create/open/reveal folder actions based on whether the installs folder exists
  - preserve the ability to switch folders without opening the full setup section
- Verification:
  - `bash skills/skillbar/scripts/run_skillbar.sh doctor`
  - `bash skills/skillbar/scripts/run_skillbar.sh inspect`
  - `bash skills/skillbar/scripts/run_skillbar.sh typecheck`
  - `bash skills/skillbar/scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash skills/skillbar/scripts/run_skillbar.sh catalog-check`
  - `bash skills/skillbar/scripts/run_skillbar.sh audit`
