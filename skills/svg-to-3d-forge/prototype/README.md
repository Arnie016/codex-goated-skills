# SVG To 3D Forge SwiftUI prototype

This folder is the generated macOS menu-bar starter that pairs with the skill package.

## What it is

- Turn simple vector assets into local 3D exports without leaving the Mac utility flow.
- A menu-bar forge for SVG scaffold presets, extrusion settings, and model export handoff.

## Included files

- `SkillMenuBarApp.swift`
- `SkillMenuBarView.swift`
- `SkillDetailView.swift`
- `SkillTheme.swift`

## Prototype sections

- SVG scaffold: create or drop a badge, coin, plaque, or keycap face and keep the editable vector source obvious.
- Extrusion controls: set format, depth, bevel, and overall size without turning the UI into a full modeling suite.
- Export handoff: show Blender readiness, output path, and a clear “reveal model” action after export succeeds.

## Notes

- Drop these files into a macOS SwiftUI target if you want to turn the sketch into a real app.
- Pair the prototype with `scripts/svg_to_3d_forge.py` when you want deterministic local SVG scaffolding and Blender export behavior.
