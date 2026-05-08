# Task Spec: Codex Limit Monitor Icon Pass

## Problem

Codex Limit Monitor already has a strong popover UI, but its menu bar icon is drawn as a tiny rounded badge with a narrow interior fill. At status-bar size the shape reads as low-contrast and partially invisible, which weakens an otherwise useful local app.

## Scope

- Keep the main Codex Limit Monitor popover and data model unchanged.
- Replace the status-bar glyph with a simpler, higher-contrast mark that reads clearly at menu bar size.
- Validate the change by rebuilding the app from source.
- Do not spend this pass on broader SkillBar polish; this run should bias toward improving a standout local tool.

## Validation

- Build Codex Limit Monitor from source after the icon change.
- Preserve the current app behavior and percentage title in the menu bar.
