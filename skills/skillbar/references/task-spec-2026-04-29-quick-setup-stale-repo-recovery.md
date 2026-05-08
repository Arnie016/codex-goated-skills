## Task Spec: Quick Setup Stale Repo Recovery

- Scope: tighten the Setup panel when the saved repo path is no longer a valid codex-goated-skills clone; do not change install/update wiring, pack parsing, or icon behavior.
- Problem: Quick Setup still surfaces a primary `Use ...` action for a stale invalid repo path, even though that action cannot finish setup. At the same time, the saved repo row hides direct open/reveal actions because the path is not a valid repo.
- Change:
  - only surface the primary quick-setup repo shortcut when SkillBar has either a valid current repo or a detected valid candidate repo
  - show direct recovery copy when the current repo selection is stale or invalid
  - allow the Setup repo row to open or reveal the saved directory path when it still exists, even if it is not a valid repo clone
  - cover the invalid-path quick-setup behavior with focused `SkillBarModel` tests
- Validation:
  - `bash scripts/run_skillbar.sh typecheck`
  - `python scripts/build_skill_market_index.py`
  - `python scripts/skill_market_loop.py sync`
  - `python scripts/skill_market_loop.py audit`
  - `bash scripts/run_skillbar.sh catalog-check`
  - `bash scripts/run_skillbar.sh audit`
