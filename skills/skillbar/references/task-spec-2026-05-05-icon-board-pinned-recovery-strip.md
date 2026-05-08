## Task Spec

- Problem: the icon-board pinned-state strip only offers `Use Default` when the saved pinned icon is stale, while the menu-bar management surface already exposes a direct detected-repo recovery shortcut.
- Goal: make pinned-icon recovery consistent and obvious by reusing one compact action strip across both surfaces.
- Scope: `apps/skillbar/SkillBarApp/Sources/Views/MenuBarView.swift`
- Guardrails:
  - keep the menu-bar-first compact layout
  - reuse the existing model recovery actions instead of adding new install logic
  - keep the change reversible and avoid unrelated catalog or metadata edits
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
