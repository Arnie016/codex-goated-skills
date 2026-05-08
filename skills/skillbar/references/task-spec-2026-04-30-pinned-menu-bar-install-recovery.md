# Task Spec: Pinned Menu Bar Install Recovery

## Problem

SkillBar shows the current pinned menu bar icon in the header and Setup surfaces, but when that pinned skill still exists in the local catalog and its installed folder is missing, those panels do not offer a direct recovery action. The user has to detour into the catalog or icon board even though SkillBar already knows how to reinstall and re-pin that skill.

## Scope

- Detect when the current pinned menu bar skill is available in the selected repo but not installed in the selected skills folder.
- Add a direct install recovery button to the main current-icon panel and the Setup menu bar icons panel.
- Reuse the existing install-and-pin behavior instead of inventing a separate recovery command.
- Add or update model tests so the recovery state stays aligned with the existing icon action logic.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh smoke-install skillbar`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
