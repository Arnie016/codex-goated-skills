---
name: skillbar
description: Build, refine, or troubleshoot SkillBar, the macOS menu bar manager for codex-goated-skills. Use when Codex needs to work on the SkillBar workspace, update the skill catalog UI, preset bundles, local install flows, or repo-driven metadata parsing for skill management.
---

# SkillBar

Use this skill when the user wants to work on the unified `SkillBar` experience: one umbrella skill plus one compact macOS menu bar app for browsing, installing, updating, and enabling goated skill presets.

## Quick Start

1. Use the local app workspace at `apps/skillbar`.
2. Treat `skills/*` in the repo as the catalog source of truth.
3. Treat `~/.codex/skills` as the installed-state source of truth unless the user picks another destination.
4. Reuse `bin/codex-goated` for install and update actions instead of inventing parallel tooling.
5. Keep the UI compact, professional, and menu-bar-native.

## Workflow

### Product Boundary

- SkillBar owns:
  - skill catalog discovery from the local repo
  - installed-state visibility
  - install and update actions
  - curated preset bundles
  - setup for repo path and Codex skills path
- SkillBar does not own:
  - secrets for other tools
  - Telegram bot token storage
  - remote marketplace sync
  - arbitrary third-party skill registries

### Editing Guidance

- Preserve a restrained menu bar layout:
  - strong hierarchy
  - compact rows
  - one monochrome top icon
  - minimal scrolling friction
- Keep action labels simple:
  - `Install`
  - `Update`
  - `Enable Preset`
  - `Choose`
- Prefer deterministic metadata parsing with graceful fallback when optional fields are missing.
- Presets should bundle existing skills; avoid making presets feel like a second catalog system.

### Validation

- Regenerate the Xcode project after changing `project.yml`.
- Run a build and tests before calling the work complete.
- Validate at least one install flow against a temporary destination so the command wiring stays honest.

## Resources

- `references/project-map.md`: app shape, metadata sources, preset rules, and validation expectations.
- `scripts/run_skillbar.sh`: local doctor, generate, build, test, and run helper for the SkillBar workspace.
