## Task Spec: Icon Header Use Default

- Scope: tighten the Icons section header without changing install, update, or catalog parsing behavior.
- Problem: the Icons screen shows the current pinned menu-bar icon state, but clearing that pin still requires leaving the icon workflow for Setup or selecting the exact pinned tile first.
- Change:
  - add a direct `Use Default` action next to the current pinned-icon shortcut in the Icons header
  - only show the action when a pinned menu-bar selection exists
  - keep the existing pinning, install, update, and reveal flows unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
