# Task Spec: Current Menu Bar Update Action

## Intent

Make the currently pinned installed skill refreshable from the always-visible Current Menu Bar Icon panel. Users should not need to browse the icon board or catalog row just to update the skill whose icon is already pinned.

## Scope

- Show an `Update Pinned` action when the pinned menu bar skill is live in the current catalog and already installed.
- Keep stale pinned icons focused on recovery, and keep pinned-but-uninstalled icons focused on reinstalling the missing skill.
- Add focused view-helper coverage for when the action should appear.
- Run SkillBar typecheck, install/update smoke checks, catalog/audit verification, and the repo market checks.

## Out Of Scope

- No change to install/update command semantics.
- No catalog, pack, manifest, or icon asset changes.
