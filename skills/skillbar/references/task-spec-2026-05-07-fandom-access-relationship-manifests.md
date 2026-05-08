# Fandom Access And Relationship Manifest Backfill

## Context

`inner-circle-director` and `parasocial-studio` are pack-covered Creator And Fandom Strategy skills with `SKILL.md`, OpenAI interface metadata, product specs, and small/large SVG icons, but no first-class `manifest.json`. SkillBar can infer enough to show them, but the catalog lacks manifest-owned audience, detail, icon fallback, and safety metadata.

## Decision

Backfill manifests for the two existing skills instead of creating a new skill. Primary owner is Creator And Fandom Strategy from `collections/SKILL_TEAMS.md`. The closest existing skills are `fan-canon-miner` and `comment-pulse-board`; this pass is materially different because it covers membership access design and relationship cadence boundaries, not canon extraction or audience-chatter clustering.

## Scope

- Add `skills/inner-circle-director/manifest.json`.
- Add `skills/parasocial-studio/manifest.json`.
- Preserve existing pack membership and SVG icon assets.
- Regenerate `catalog/index.json`.

## Safety

Both manifests keep the workflow local-first and bounded to public or user-authorized material. They explicitly reject stalking, covert profiling, rumor laundering, harassment, exploitative spend pressure, pseudo-romantic framing, and dependency hooks.

## Verification

- `jq empty` for the new manifests.
- `python scripts/build_skill_market_index.py`.
- `python scripts/skill_market_loop.py sync`.
- `python scripts/skill_market_loop.py audit`.
- `bash scripts/run_skillbar.sh catalog-check`.
- `bash scripts/run_skillbar.sh audit`.
- SkillBar typecheck and install/update smoke checks after catalog regeneration.
