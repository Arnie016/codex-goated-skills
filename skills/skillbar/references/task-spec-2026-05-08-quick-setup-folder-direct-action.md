# Task Spec: Quick Setup Folder Direct Action

## Intent

Make the Quick Setup surface keep installs-folder recovery direct even when the primary repo setup action is also available. Creating `~/.codex/skills` is a common local setup step and should not be hidden inside the secondary folder options menu.

## Scope

- Keep the existing repo quick-setup primary action.
- Show `Create Folder` directly whenever the installed skills folder is missing.
- Keep the create-folder action visually secondary when a repo primary action is already present.
- Update focused view helper tests and run the SkillBar validation path.

## Out Of Scope

- No install/update command changes.
- No catalog, pack, or manifest restructuring.
