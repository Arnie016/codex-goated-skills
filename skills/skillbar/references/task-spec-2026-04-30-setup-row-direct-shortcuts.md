# Task Spec: Setup Row Direct Shortcuts

## Goal

Make the Setup panel more direct for two common recovery actions:

- switch the active repo root to a detected local clone without leaving the Repo Root row
- switch installs back to `~/.codex/skills` from the Installed Skills row

## Why

SkillBar already exposes these actions through Quick Setup, but the row that shows the current path still makes users hunt elsewhere for the fix. That is avoidable friction in the highest-frequency setup surface.

## Scope

- add row-level shortcut state to `SkillBarModel`
- surface inline secondary actions in `MenuBarView`
- add focused tests for the new labels and visibility logic

## Non-Goals

- no install/update plumbing changes
- no catalog parsing changes
- no large setup layout rewrite
