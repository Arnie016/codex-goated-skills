# Active Search Chip Width

## Goal

Keep SkillBar's Active View strip compact when a user types a long search query.

## Scope

- Sanitize whitespace in the visible search-scope chip.
- Compact long search text with a middle `...` marker so the menu-bar panel stays readable.
- Cover the formatting helper with focused view tests.

## Out Of Scope

- No catalog metadata changes.
- No install, update, or pack command behavior changes.
