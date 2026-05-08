# Task Spec: Daily App Manifest Backfill

Date: 2026-05-07

## Goal

Move the Daily Context And App-Specific Bars skills onto manifest-owned catalog metadata so SkillBar and `catalog/index.json` show stable names, categories, ratings, docs paths, icon references, and system-symbol fallbacks.

## Scope

- Add manifests for `flight-scout`, `gain-tracker`, `on-this-day`, `on-this-day-bar`, `telebar`, and `trading-archive`.
- Emit existing manifest-owned fields through the generated catalog index so names, categories, ratings, docs, tags, and detail lines are not silently dropped.
- Preserve existing `SKILL.md`, `agents/openai.yaml`, assets, pack membership, runner scripts, app source, project files, signing files, and install/update behavior.
- Regenerate and audit the catalog after metadata changes.

## Non-Goals

- Do not create a new skill.
- Do not touch protected app source or Xcode project surfaces.
- Do not add network behavior, tokens, account setup, or remote sync beyond each existing skill boundary.
