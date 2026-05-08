# Task Spec: Icon Source Label Preview Match

Date: 2026-05-07

## Goal

Make SkillBar's selected icon detail source chip name the same artwork file that the large preview prefers.

## Scope

- Keep compact rows and library list labels preferring `icon_small`.
- Make large preview detail labels prefer `icon_large`, falling back to `icon_small`.
- Add focused unit coverage for deterministic source-label ordering.

## Non-Goals

- Do not redesign the icon board.
- Do not change install, update, pack, or catalog parsing behavior.
