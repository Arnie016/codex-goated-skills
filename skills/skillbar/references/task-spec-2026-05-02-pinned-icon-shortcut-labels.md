## Task Spec: Pinned Icon Shortcut Labels

- Scope: tighten the pinned menu bar icon shortcut labels across Setup and the current-icon surface without changing reveal, install, or pin logic.
- Problem: the shared shortcut label still says `Show Current` or `Current Unavailable`, which is indirect and does not explain whether the user can open the pinned catalog tile, needs to pin an icon first, or is looking at a stale snapshot.
- Change:
  - make the reveal action label explicit when the pinned icon can be opened from the current catalog
  - show a distinct blocked label when nothing is pinned yet
  - show a distinct blocked label when the saved pinned icon no longer exists in the current catalog
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
