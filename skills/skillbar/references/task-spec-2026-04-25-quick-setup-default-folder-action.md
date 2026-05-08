## Task Spec: Quick Setup Default Folder Action

- Scope: tighten the no-repo quick-setup controls so the third button maps cleanly to the action it performs.
- Why now: the current button can read like a status label while still opening the folder picker, and it leaves the common "go back to the standard installs path" recovery buried in deeper setup controls.
- Planned change:
  - keep the existing install and repo-selection logic unchanged
  - update the quick-setup button so custom installs paths surface a one-tap "Use Default" reset
  - keep the folder chooser explicit when the default installs path is already selected
- Verification:
  - `bash skills/skillbar/scripts/run_skillbar.sh typecheck`
  - `bash skills/skillbar/scripts/run_skillbar.sh smoke-install skillbar`
  - `bash skills/skillbar/scripts/run_skillbar.sh smoke-update skillbar`
