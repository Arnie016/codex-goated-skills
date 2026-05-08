# Task Spec: Icon Preview Asset Order

Date: 2026-05-07

## Goal

Make SkillBar's icon board and selected-icon detail preview the large catalog artwork when a skill ships both small and large icon assets.

## Scope

- Keep compact rows and menu-bar-style surfaces preferring `icon_small`.
- Make large preview surfaces prefer `icon_large`, falling back to `icon_small`.
- Add focused unit coverage for deterministic icon asset ordering.

## Non-Goals

- Do not redesign the icon board.
- Do not rewrite icon metadata or regenerate individual SVG artwork.
- Do not change install, update, or pack behavior.
