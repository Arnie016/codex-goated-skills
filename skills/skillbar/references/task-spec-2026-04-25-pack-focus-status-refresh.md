## Task Spec: Pack Focus Status Survives Refresh

- Scope: keep SkillBar's status header aligned with the active pack-focus state after catalog refreshes and path-driven refresh actions.
- Why now: the current pack browser can remain focused to a repo pack while the status header falls back to generic catalog copy, which makes the filtered state feel hidden again.
- Planned change:
  - keep existing pack filtering and command execution behavior unchanged
  - teach the catalog-ready status builder to preserve focused-pack messaging when a pack focus is still active
  - add model tests covering manual refresh and installs-folder refresh while a pack focus is active
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
