## Task Spec

- Scope: tighten the Setup panel guardrails so icon cleanup starts from the place users already look for catalog health.
- Problem: Setup still shows missing-icon and duplicate-name counts as passive badges, which makes obvious cleanup actions feel hidden even though SkillBar already has an icon board.
- Change:
  - turn the warm guardrail chips in Setup into direct shortcuts into the Icons section
  - clear transient search or pack scope before jumping so the review starts from the full catalog
  - preselect the first missing-art or repeated-name skill when a matching issue exists
  - keep catalog parsing and install/update plumbing unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh test`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
