# Task Spec: SkillBar Active View Options Menu

## Problem

The Active View recovery panel still exposes `Clear Search`, `Clear Pack`, and `Reset View` as peer buttons. In the menu-bar surface this gives narrow secondary cleanup actions the same visual weight as the direct reset path.

## Scope

- Keep `Reset View` as the direct primary recovery action.
- Move granular search and pack clear actions behind a compact `View Options` menu.
- Reuse the existing secondary-action menu pattern so setup, pack recovery, and active view controls behave consistently.

## Verification

- `bash scripts/run_skillbar.sh typecheck`
- Existing catalog and audit checks after the edit
