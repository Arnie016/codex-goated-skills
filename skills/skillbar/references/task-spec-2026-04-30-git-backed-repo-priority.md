# Task Spec: Prefer Git-Backed Repo Roots In SkillBar

## Problem

SkillBar currently treats any directory with `skills/` plus `bin/codex-goated` as equally valid during repo auto-detection. In this workspace that allows shallow staging folders and copied snapshots to outrank the real git checkout just because they are closer to the filesystem root.

## Change

- Keep the existing repo-root validity check so local-first snapshots still work when selected manually.
- Tighten auto-detection ranking so git-backed checkouts sort ahead of non-git lookalikes.
- Add regression coverage for repo-root prioritization so shallow wrapper or staging folders do not become the default choice over a real clone.

## Validation

- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh smoke-install skillbar`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
