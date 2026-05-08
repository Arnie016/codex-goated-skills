# Task Spec: Final Legacy Manifest Backfill

## Context

SkillBar and the generated catalog now prefer manifest-owned metadata for category, detail copy, audience, tags, icon paths, and SF Symbol fallbacks. The remaining catalog-visible legacy skills with `SKILL.md` and existing icon assets but no `manifest.json` are:

- `clip-to-canon-finder`
- `dark-pdf-studio`
- `iconography-lab`
- `lore-drop-planner`
- `minecraft-essentials`
- `minecraft-skin-studio`
- `myth-merch-studio`
- `ritual-engine`

## Scope

Backfill first-class manifests for these existing skills only. Preserve the current `SKILL.md`, `agents/openai.yaml`, icon assets, scripts, references, and pack membership. Regenerate the catalog after the metadata change and run the standard SkillBar/catalog checks.

## Team Review

No new skill is being created.

- Primary teams involved: Creator And Fandom Strategy, Documents, Decks, And Creative Export, and Games And Play from `collections/SKILL_TEAMS.md`.
- Closest existing skills: the work is the existing skills themselves, not a proposed replacement. Backfilling metadata is materially different from adding a new workflow because it improves SkillBar discoverability and icon fallback quality without expanding the catalog surface.
- Product reason: these eight skills already appear in packs and have icons, but missing manifests make their SkillBar catalog rows weaker than adjacent skills.

## Acceptance Checks

- Each listed skill has valid JSON at `skills/<id>/manifest.json`.
- Each manifest includes category, status, short description, audience, tags, install command, docs paths, detail lines, file path hints, icon paths, and `system_symbol`.
- Catalog generation/sync/audit succeeds.
- SkillBar catalog-check and audit succeed.
- SkillBar typecheck and install/update smoke checks still pass.
