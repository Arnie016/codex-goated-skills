# Task Spec

- Problem: the icon board can be narrowed by both search text and pack focus, but the live-icon reveal path only clears search. When the pinned skill sits outside the focused pack, `Show Live Icon` does not actually reveal it.
- Goal: make the icon board surface its current scope directly and ensure the live-icon reveal path clears whichever local scopes are blocking the pinned skill.
- Scope:
  - update `apps/skillbar/SkillBarApp/Sources/App/SkillBarModel.swift`
  - update `apps/skillbar/SkillBarApp/Sources/Views/MenuBarView.swift`
  - add or extend `apps/skillbar/SkillBarApp/Tests/SkillBarModelTests.swift`
- Validation:
  - `bash scripts/run_skillbar.sh doctor`
  - `bash scripts/run_skillbar.sh inspect`
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh test`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
