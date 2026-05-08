# Task Spec: Pinned Menu Bar Recovery Open + Reveal

## Problem

When a pinned menu bar icon goes stale because the selected repo no longer contains that skill, SkillBar can already detect another viable repo clone and offer `Use Detected Repo`. But the pinned-icon recovery surfaces still do not let the user open or reveal that detected repo before switching, even though Quick Setup and pack recovery already do.

## Scope

- Add direct `Open` and `Reveal` actions for the detected repo candidate on the pinned menu bar recovery surfaces.
- Reuse the existing detected-repo selection and quick-setup behavior instead of introducing new recovery logic.
- Keep the change compact and menu-bar-first.
- Add a focused regression test for the label copy so the pinned recovery wording stays aligned with current-vs-detected repo state.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
