# Task Spec: Fandom Signal Manifests

## Context

The catalog still has older audience-strategy skills that rely on `SKILL.md` plus `agents/openai.yaml` fallback metadata. `comment-pulse-board` and `reputation-heatmap` already have product specs, pack coverage, and SVG icons, but no `manifest.json`, leaving SkillBar without manifest-owned detail lines, docs paths, and SF Symbol fallbacks.

## Scope

- Add first-class manifests for `comment-pulse-board` and `reputation-heatmap`.
- Keep the existing skill IDs, pack membership, default prompts, and asset direction unchanged.
- Regenerate catalog output and run the repo/SkillBar checks that apply to metadata changes.

## Non-Goals

- Do not create a new skill.
- Do not change audience/fandom pack membership.
- Do not rewrite SkillBar UI code in this pass.

## Verification

- `jq empty` on the new manifests.
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `bash scripts/run_skillbar.sh typecheck`
- smoke install/update checks for `skillbar` to keep runner paths honest.
