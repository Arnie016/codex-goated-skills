## Task Spec

- Scope: tighten the existing SkillBar icon-board guardrail UX without changing catalog parsing or install/update plumbing.
- Problem: the icon guardrail counts expose missing-art and duplicate-name issues, but they read like passive status instead of direct actions.
- Change:
  - make the guardrail chips in SkillBar's icon surfaces act like drill-down controls
  - send missing-art chips into the missing-art icon filter
  - send duplicate-name chips into the icon board with the first repeated skill selected
  - preserve current scope for visible issue chips and clear scope only for whole-catalog review chips
- Validation:
  - `bash skills/skillbar/scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash skills/skillbar/scripts/run_skillbar.sh catalog-check`
  - `bash skills/skillbar/scripts/run_skillbar.sh audit`
