# Task Spec: Active Scope Clear Chips

Date: 2026-05-07

## Goal

Make SkillBar's active search and pack scope controls directly clearable from the visible filter chips, without forcing users through the view options menu.

## Scope

- Keep the existing Reset View and View Options actions.
- Make active scope chips compact and clearable with an explicit close icon.
- Cap long scope labels so search text or pack names cannot overflow the menu.
- Add focused unit coverage for deterministic scope-chip label copy.

## Non-Goals

- Do not redesign the catalog browser or pack focus model.
- Do not change install, update, pack, catalog parsing, or icon artwork behavior.
