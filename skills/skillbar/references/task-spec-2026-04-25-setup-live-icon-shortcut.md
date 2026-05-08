## Task Spec: Setup Live Icon Shortcut

- Scope: tighten the Settings surface so the currently live menu bar icon is one tap away, not only discoverable after switching into the Icons board.
- Why now: SkillBar already preserves pinned icon state and can reveal it inside the Icons section, but Settings still leads with a generic "Open Icons" action even when a specific live icon is already active.
- Planned change:
  - keep install, pin, snapshot, and reveal behavior unchanged
  - add a direct Settings action that opens the Icons section focused on the live pinned icon when one exists
  - preserve the existing generic icon-board entry point when nothing is pinned yet
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
