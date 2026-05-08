## Task Spec: Icon Scope Recovery

- Scope: tighten the generic SkillBar icon-board entry points and recovery affordances without touching catalog parsing or install/update plumbing.
- Problem: Setup and empty-state shortcuts can open Icons while search or pack focus is still active, which hides much of the board and makes icon cleanup feel inconsistent.
- Change:
  - route generic "Open Icons" actions to the full icon board instead of preserving stale search or pack scope
  - surface a compact reset affordance inside the Icons header when the board is currently filtered
  - keep targeted guardrail drill-downs unchanged so issue-specific jumps still preselect the first matching entry
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
