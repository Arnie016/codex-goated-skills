# Branch Brief Bar SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Turn the current branch into a clean review handoff before context spills.
- A menu-bar git brief for branch health, touched areas, changed files, recent commits, and the next review action.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Branch snapshot: show the branch, compare base, compare-base reason, upstream relation, and working tree counts as one calm top card instead of making the user reconstruct it from multiple git commands.
- Handoff brief: surface the touched areas, changed files, recent commits, and next action as a short reviewer-facing brief that is ready to paste into chat or a PR update.
- Review flow: keep copy brief, open repo, reveal diff, and blocked-state actions together so the jump from shell work to review handoff feels deliberate and calm.
- Review base: if the branch only tracks its own remote feature branch, the prototype should still frame the handoff against a main-like review base such as the remote default branch, main, master, or trunk unless the user explicitly pins another ref.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- Pair the prototype with `scripts/branch_brief.py` when you want deterministic local data feeding the UI.
