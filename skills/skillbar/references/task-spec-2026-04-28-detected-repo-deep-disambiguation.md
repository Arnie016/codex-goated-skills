## Task Spec: Detected Repo Labels Stay Unique Across Nested Clones

- Scope: tighten detected local clone labels so repo-switch actions stay unique even when clones share the same repo basename and immediate parent folder name.
- Why now: SkillBar now scans multiple wrapped and publish-style checkouts. One-level `parent/repo` labels still collide for some nested copies, which makes quick repo switching less trustworthy.
- Planned change:
  - keep repo discovery, normalization, and switching behavior unchanged
  - preserve simple `Use repo-name` labels when the basename is unique
  - add just enough parent path context to make duplicate clone labels unique
  - fall back to the abbreviated full path only if a shorter unique label cannot be derived
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh test` if sandbox permits
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
