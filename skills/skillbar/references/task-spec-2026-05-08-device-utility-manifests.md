# Task Spec: Device Utility Manifest Backfill

Date: 2026-05-08

## Goal

Move two existing macOS System And Device Utilities skills onto manifest-owned catalog metadata so SkillBar shows stable names, categories, docs paths, local-first positioning, icon references, and system-symbol fallbacks.

## Scope

- Add manifests for `find-my-phone-studio` and `vibe-bluetooth`.
- Preserve existing `SKILL.md`, `agents/openai.yaml`, assets, references, runner scripts, app workspaces, pack membership, and install/update behavior.
- Regenerate and audit the catalog after metadata changes.

## Non-Goals

- Do not create a new skill.
- Do not add provider credentials, tokens, Bluetooth automation, account sync, or hidden network behavior.
- Do not change Swift app source, Xcode project files, or runner scripts.
