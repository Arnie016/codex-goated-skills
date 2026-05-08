## Task Spec

- Scope: tighten SkillBar's scoped-browsing recovery inside the existing menu-bar UI.
- Problem: search text, pack focus, and icon-board filters can stack into a narrow view, but the escape actions are split across separate controls, which makes recovery feel sticky.
- Change:
  - add a single reset-view action for scoped icon browsing
  - reuse it in icon empty states and scope banners
  - keep install, update, catalog, and parser logic unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
