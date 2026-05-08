## Task Spec: Pack Available Member Copy

- Scope: tighten SkillBar pack-browser copy for broken or partially resolved packs without changing install/update wiring or catalog parsing.
- Problem: pack rows still fall back to raw declared member counts when local catalog resolution is partial or zero, which overstates what users can actually browse or install from the current repo.
- Change:
  - derive pack row summary copy from resolved local members first
  - show explicit available-vs-declared copy when some or all members are missing
  - add unit coverage for broken-pack browse labels and focus status copy
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
