## Task Spec

- Scope: tighten SkillBar's main search recovery flow inside the existing menu-bar UI.
- Problem: search text persists across sections, but the main search field offers no direct clear/reset action, which makes empty states and pack/icon navigation feel stickier than they should.
- Change:
  - add a lightweight model helper for clearing search
  - add a direct clear button beside the main search field
  - keep the change local to SkillBar UI state and avoid install/catalog plumbing edits
- Validation:
  - `bash skills/skillbar/scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash skills/skillbar/scripts/run_skillbar.sh catalog-check`
  - `bash skills/skillbar/scripts/run_skillbar.sh audit`
