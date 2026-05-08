## Task Spec: Icon Filter Scope Counts

- Scope: align the Icons board filter counts and empty-state guidance with the current search or pack-focused view.
- Why now: the icon grid already scopes tiles to the active search and pack focus, but the filter pills still advertise whole-catalog totals, which makes `Pinned`, `Installed`, and `Missing Art` feel misleading once the user narrows the board.
- Planned change:
  - keep install, update, and pin behavior unchanged
  - make icon filter counts derive from the current icon board scope instead of the full catalog
  - tighten the icon-board summary and empty-state copy so they explain the narrowed scope directly
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
