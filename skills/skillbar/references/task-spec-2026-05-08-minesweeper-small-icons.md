# Task Spec: Minesweeper Small Icon Readability

## Context

SkillBar surfaces `icon_small` assets in compact catalog rows and icon pickers. The `minefield-menubar` and `minesweeper-menubar` small SVGs currently include long text captions inside the artwork, which is not readable at SkillBar row size and weakens the icon board.

## Scope

- Keep both existing Games And Play skills.
- Preserve their current board-first visual direction and distinct accents.
- Remove unreadable text from the small SVG icons.
- Add simple icon-scale status marks so the lower area still carries useful game meaning.

## Non-Goals

- Do not merge or retire either skill in this pass.
- Do not create a new skill.
- Do not change pack membership, install flow, or Swift app behavior.

## Skill Factory Review

Primary team: Games And Play.

Closest existing skills: `minefield-menubar` and `minesweeper-menubar` are the closest pair to each other. This pass improves their surfaced icon assets instead of creating a duplicate or deciding a retirement while the worktree already contains unrelated changes.
