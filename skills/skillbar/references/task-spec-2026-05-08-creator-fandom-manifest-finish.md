# Creator Fandom Manifest Finish

## Context

`clip-to-canon-finder`, `iconography-lab`, `lore-drop-planner`, `myth-merch-studio`, and `ritual-engine` are pack-covered Creator And Fandom Strategy skills with `SKILL.md`, OpenAI interface metadata, product specs, and readable small/large SVG icons, but no first-class `manifest.json`. SkillBar can infer basic names and descriptions, but the catalog lacks manifest-owned category, audience, detail, docs, and SF Symbol fallback metadata.

## Decision

Backfill manifests for the five existing skills instead of creating a new skill. Primary owner is Creator And Fandom Strategy from `collections/SKILL_TEAMS.md`. The closest existing skills are `fan-canon-miner`, `comment-pulse-board`, `parasocial-studio`, and `story-arc-board`; this pass is materially different because it completes metadata for existing clip scoring, icon-code mapping, lore scheduling, merch translation, and ritual-cadence workflows rather than adding another audience analysis surface.

## Scope

- Add `skills/clip-to-canon-finder/manifest.json`.
- Add `skills/iconography-lab/manifest.json`.
- Add `skills/lore-drop-planner/manifest.json`.
- Add `skills/myth-merch-studio/manifest.json`.
- Add `skills/ritual-engine/manifest.json`.
- Preserve existing pack membership, `SKILL.md`, `agents/openai.yaml`, product specs, and SVG icon assets.
- Regenerate `catalog/index.json`.

## Safety

The manifests keep the workflows local-first and bounded to public or user-authorized material. They surface the existing boundaries against stalking, covert profiling, rumor laundering, harassment, manipulative ambiguity, quote-mining, coercive rituals, unlicensed likeness use, and audience pressure tactics.

## Verification

- `jq empty` for the five new manifests.
- `python scripts/build_skill_market_index.py`.
- `python scripts/skill_market_loop.py sync`.
- `python scripts/skill_market_loop.py audit`.
- `bash scripts/run_skillbar.sh catalog-check`.
- `bash scripts/run_skillbar.sh audit`.
- SkillBar typecheck and install/update smoke checks after catalog regeneration.
