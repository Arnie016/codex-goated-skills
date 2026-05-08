## Task Spec: Detected Repo Labels Stay Specific

- Scope: make detected local clone actions name the actual repo target across SkillBar's repo-switch surfaces.
- Why now: SkillBar now surfaces multiple local clones, including publish and tmp copies. Generic labels like `Use detected repo` make common repo switching less direct and harder to trust.
- Planned change:
  - keep repo discovery, normalization, and switching behavior unchanged
  - derive short detected-repo labels from the repo path instead of generic copy
  - disambiguate duplicate clone names by including the parent folder in the action label when needed
  - reuse the same label helper in quick actions, setup shortcuts, and detected-repo list rows
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
