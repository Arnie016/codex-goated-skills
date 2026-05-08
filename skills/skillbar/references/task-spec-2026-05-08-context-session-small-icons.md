# Task Spec: Context Shelf And Session Arcade Small Icons

Date: 2026-05-08

## Problem

`context-shelf` and `session-arcade` still used generated-template 512px icons with long skill names, category labels, initials, and a "Generated Mac skill" caption. SkillBar uses these assets in compact catalog and icon-board surfaces where that text becomes unreadable and makes the skills look less intentional than newer icon passes.

## Scope

- Replace `skills/context-shelf/assets/icon-small.svg` and `skills/context-shelf/assets/icon.svg` with a text-free shelf/resume mark.
- Replace `skills/session-arcade/assets/icon-small.svg` and `skills/session-arcade/assets/icon.svg` with a text-free controller/play-session mark.
- Remove the generated-template caption from the matching large preview assets without changing manifests, pack membership, install behavior, or Swift code.

## Non-Goals

- No new skill creation.
- No pack membership changes.
- No changes to SkillBar install/update logic.

## Verification

- Validate edited SVG syntax.
- Regenerate and sync the catalog.
- Run the required skill-market audit and SkillBar catalog/audit checks.
