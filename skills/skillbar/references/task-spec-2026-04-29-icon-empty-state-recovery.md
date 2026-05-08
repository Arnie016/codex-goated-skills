## Task Spec: Icon Empty State Recovery

- Scope: tighten the empty-state recovery path for the SkillBar icon board without changing icon parsing or menu-bar pinning behavior.
- Problem: the Icons section still falls back to a dead-end "No icons match" message even though Discover, Installed, and Packs now offer direct recovery actions when search, pack focus, or repo setup hides the expected content.
- Change:
  - add a contextual empty state for the Icons section
  - surface Reset View when search or pack focus is hiding icons
  - surface setup recovery when no valid repo is selected
  - keep targeted icon drill-down behavior unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
