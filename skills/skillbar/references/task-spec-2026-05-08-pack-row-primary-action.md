# Task Spec: Pack Row Primary Action

Date: 2026-05-08

## Goal

Make SkillBar pack rows easier to scan by keeping only the clearest next pack action visually primary.

## Scope

- Keep install/update, pack catalog browsing, and icon browsing visible in the pack row.
- Prefer `Install` as the primary action when a pack is incomplete and runnable.
- Prefer `Browse` as the primary action when there is no stronger install action or the pack is already complete.
- Keep `Open Catalog` secondary when the pack filter is already active.
- Cover the decision logic with focused Swift Testing assertions.

## Out Of Scope

- No changes to pack metadata, install/update execution, CLI calls, or catalog parsing.
- No new skills or pack membership changes.
