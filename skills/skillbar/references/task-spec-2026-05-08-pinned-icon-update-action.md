# Task Spec: Pinned Icon Update Action

## Intent

Keep `Update` directly available in the selected icon detail even when the selected skill is already pinned to the menu bar. Pinned installed skills previously only exposed `Use Default` and `Reveal` from the icon board, pushing the refresh path back into catalog rows.

## Scope

- Show the selected-icon `Update` action for every installed skill.
- Preserve `Use Default`, pin, install, install-only, and reveal behavior.
- Add focused view helper coverage for pinned installed icons.
- Run SkillBar typecheck, install/update smoke checks, and catalog/audit verification.

## Out Of Scope

- No install/update command semantics change.
- No catalog, pack, manifest, or icon asset changes.
