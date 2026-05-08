## Task Spec

- Problem: the SkillBar icon board mixes whole-catalog counts with search-scoped icon results, so filter pills, header chips, and empty states can disagree with the tiles currently shown.
- Goal: keep the icon board compact while making counts and guidance reflect the current search and filter scope, especially for pinned and missing-art views.
- Scope: update `apps/skillbar/SkillBarApp/Sources/Views/MenuBarView.swift` only; do not change catalog parsing, install behavior, or pack logic.
- Validation: run SkillBar `typecheck`, `catalog-check`, `audit`, plus the AGENTS.md Python maintenance commands after the UI copy/count changes.
