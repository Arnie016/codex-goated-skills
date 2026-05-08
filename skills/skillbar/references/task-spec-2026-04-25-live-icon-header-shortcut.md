## Task Spec: Live Icon Header Shortcut

- Scope: tighten the Icons header so the currently live menu bar icon is easy to jump back to when search or filters hide it.
- Why now: SkillBar already keeps the pinned icon state and banner accurate, but the top-level Icons header still leads with reset-only wording and makes the current live icon feel harder to revisit than it should.
- Planned change:
  - keep the existing pinned snapshot, reveal, and install behavior unchanged
  - add a direct header shortcut that reveals the live icon when it is hidden from the current board state
  - normalize reset copy to `Use Default` so the same action reads consistently across the icon surface
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh smoke-install skillbar`
  - `bash scripts/run_skillbar.sh smoke-update skillbar`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
