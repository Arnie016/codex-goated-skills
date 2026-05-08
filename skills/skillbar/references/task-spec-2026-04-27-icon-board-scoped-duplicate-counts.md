# Task Spec: SkillBar icon-board scoped duplicate counts

## Goal

Make the icon-board quality chips consistent when SkillBar is narrowed by search text or pack focus.

## Scope

- Keep the existing whole-catalog duplicate-name signal visible.
- Add a scoped duplicate-name count for the current icon-board results.
- Reuse one duplicate-count helper so the model and UI stay aligned.
- Add focused test coverage for catalog-wide versus scoped duplicate counting.

## Non-Goals

- No install-flow changes.
- No catalog metadata edits.
- No broad menu layout rewrite.
