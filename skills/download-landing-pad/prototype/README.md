# Download Landing Pad SwiftUI prototype

This folder contains a menu-bar-first SwiftUI starter for the skill package.

## What it sketches

- A recent-arrivals lane for the files that just landed in Downloads.
- A readiness strip and health panel that make the local doctor state visible before the first rename or move.
- A rename dock that keeps the suggested filename close to the selected file.
- Route chips and dispatch actions so the next move is obvious without opening Finder first.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- Arrival queue: show the newest files with age, size, and source hints so the right item is obvious immediately.
- Health checks: show whether Downloads access, metadata hints, reveal support, and copy-path support are ready before the user trusts the lane.
- Rename dock: keep the suggested filename editable and visibly tied to the selected file.
- Route actions: keep reveal, copy-path, and explicit destination choices in the same compact panel.

## Notes

- The sample data is static on purpose so the shell can be transplanted into a real macOS target without hidden dependencies.
- Typecheck the prototype with:

```bash
xcrun swiftc -module-cache-path /tmp/codex-goated-swift-module-cache -typecheck \
  skills/download-landing-pad/prototype/SkillTheme.swift \
  skills/download-landing-pad/prototype/SkillDetailView.swift \
  skills/download-landing-pad/prototype/SkillMenuBarView.swift \
  skills/download-landing-pad/prototype/SkillMenuBarApp.swift
```
