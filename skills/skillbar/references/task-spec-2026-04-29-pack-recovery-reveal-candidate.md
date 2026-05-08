## Task

Add a direct reveal action to the broken pack recovery card so users can inspect the detected repo clone before switching SkillBar to it.

## Scope

- Keep the change limited to the pack recovery UX in SkillBar.
- Reuse existing repo-label and Finder-reveal behavior instead of adding new repo discovery logic.
- Add model coverage for the new reveal label to keep the shortcut wording stable.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh test`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
