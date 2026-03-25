# SkillBar Project Map

## Workspace

- App workspace: `apps/skillbar`
- Umbrella skill package: `skills/skillbar`

## Core Responsibilities

- Read repo skills from `skills/*`
- Read installed state from `~/.codex/skills`
- Run `bin/codex-goated install` and `bin/codex-goated update`
- Expose curated presets that bundle existing skills

## Main Files

- `SkillBarApp/Sources/App/SkillBarModel.swift`
  - state, setup paths, refresh, install, and preset actions
- `SkillBarApp/Sources/Services/SkillCatalogService.swift`
  - metadata parsing and repo discovery
- `SkillBarApp/Sources/Services/SkillInstallService.swift`
  - deterministic command descriptor and process execution
- `SkillBarApp/Sources/Views/MenuBarView.swift`
  - compact menu bar UI

## Guardrails

- Do not add token storage for other products here.
- Keep install logic delegated to existing CLI tooling.
- Keep preset bundles static and understandable in v1.
