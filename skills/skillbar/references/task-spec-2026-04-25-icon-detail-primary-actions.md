# Task Spec

- Problem: the Icons detail card branches into several different button layouts, repeats `Use Default Icon`, and does not mirror the clearer primary action already shown on each icon tile.
- Goal: make the detail card lead with the same state-aware primary action as the tile, keep secondary actions compact, and leave install, update, and pin-only paths available.
- Scope: `apps/skillbar/SkillBarApp/Sources/Views/MenuBarView.swift` only.
- Validation: `bash scripts/run_skillbar.sh typecheck`, `bash scripts/run_skillbar.sh smoke-install skillbar`, `bash scripts/run_skillbar.sh smoke-update skillbar`.
