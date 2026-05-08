# Task Spec: Catalog Scope Surface

## Problem
SkillBar now supports search and pack-scoped browsing, but the active scope is mostly implicit in normal Discover and Installed states. Users can land on a filtered list after browsing a pack and have no compact, obvious way to see the active scope or clear it without switching sections.

## Goal
Make active catalog scope visible and reversible from the main menu flow. Keep the change compact and menu-bar-first.

## Planned Change
- Add a small active-scope strip below search in the shared control panel.
- Surface current search text and pack focus as chips.
- Add direct actions to clear search, clear pack focus, or reset the whole scoped view.
- Reuse the same affordance across Discover, Installed, Packs, and Icons rather than only in empty states.

## Guardrails
- Do not change install/update behavior.
- Do not expand SkillBar into a larger dashboard.
- Preserve existing empty-state recovery actions.

## Validation
- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
