# Task Spec: Pinned Row Install Dedupe

Date: 2026-05-08

## Goal

Make catalog rows less repetitive when the current menu bar icon is pinned but its underlying skill is not installed.

## Scope

- Keep the direct `Install Skill` recovery action visible for pinned-but-uninstalled rows.
- Hide the generic `Install` row action in that specific state, because it duplicates the same user intent.
- Promote `Install Skill` so the remaining recovery action is still obvious.
- Add focused helper coverage in the existing SkillBar view tests.

## Non-Goals

- Do not change `bin/codex-goated` install/update behavior.
- Do not alter catalog metadata, pack membership, or skill manifests.
- Do not create a new skill.

## Verification

- `bash scripts/run_skillbar.sh doctor`
- `bash scripts/run_skillbar.sh inspect`
- `bash scripts/run_skillbar.sh typecheck`
- Required catalog/index/audit commands from the automation prompt
- SkillBar smoke install/update checks for the install/update surface
