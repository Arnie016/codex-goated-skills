## Task Spec: Detected Repo Primary Action

- Scope: tighten the no-repo quick-setup controls so the best detected local clone is available as a first-click action.
- Why now: SkillBar already discovers likely repo roots, but the no-repo state still leads with manual folder picking and buries the common recovery path in the detected-repo list below.
- Planned change:
  - keep repo discovery and normalization logic unchanged
  - update the no-repo quick-setup action row so a detected repo becomes the primary action when available
  - preserve manual repo picking and the detailed detected-repo list for fallback switching
- Verification:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh doctor`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
