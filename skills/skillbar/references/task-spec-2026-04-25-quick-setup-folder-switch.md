## Task Spec: Quick Setup Folder Switch Shortcut

- Scope: restore direct installs-folder switching inside the no-repo quick-setup panel while keeping the new default-reset shortcut.
- Why now: the current quick-setup controls swap the folder picker out for "Use Default" when a custom installs path is active, which forces users into Settings for the common "pick a different custom folder" path.
- Planned change:
  - keep the existing create/open-folder and default-reset behavior
  - make the quick-setup panel always expose a direct folder chooser
  - keep the settings escape hatch, but stop requiring it for basic installs-path switching
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
