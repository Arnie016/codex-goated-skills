## Task Spec: Pinned Icon Reveal Guard

- Scope: tighten the current menu-bar icon shortcuts in Setup and Icons without changing install, update, or catalog parsing behavior.
- Problem: `Open Current` and `Show Current` stay active even when SkillBar is using the default icon or when the pinned icon only exists in snapshot state outside the active catalog, which makes the shortcut jump to an unrelated first tile.
- Change:
  - expose whether the pinned menu-bar icon is actually revealable in the current catalog
  - disable and relabel the reveal shortcuts when there is no live catalog tile to open
  - keep the existing default-icon reset and pinning flows unchanged
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
