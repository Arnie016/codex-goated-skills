# Task Spec: Pinned Uninstalled Row Action

## Intent

Make catalog rows use direct copy when the current menu-bar icon points at a skill that is not installed yet. The detail panel already calls this state `Install Skill`; the row should not imply the user needs to pin the icon again.

## Scope

- Add a catalog-row accessory action for pinned-but-uninstalled skills.
- Keep the existing install command path and pinned-icon persistence behavior.
- Update focused model and view-helper tests.
- Run the SkillBar validation path plus catalog/audit checks.

## Out Of Scope

- No install/update CLI changes.
- No catalog, pack, manifest, or icon metadata restructuring.
