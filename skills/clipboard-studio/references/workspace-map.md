# Context Assembly Workspace Map

Default workspace: `apps/clipboard-studio`

Use this reference when the request is about the bundled macOS app instead of generic clipboard product shaping.

## Targets

- `ClipboardStudio`: menu bar application target named `Context Assembly`
- `ClipboardStudioTests`: unit-test bundle for pack formatting, history behavior, and focus-state handling

## Main Files

- `project.yml`: XcodeGen source of truth for targets, bundle metadata, and scheme wiring
- `ClipboardStudioApp/Info.plist`: app display name and Apple Events permission text
- `ClipboardStudioApp/Sources/App/ClipboardStudioApp.swift`: `MenuBarExtra`, settings scene, single-instance guard
- `ClipboardStudioApp/Sources/App/ClipboardStudioDomain.swift`: core models for clipboard entries, pack items, focus snapshots, and persistence helpers
- `ClipboardStudioApp/Sources/App/ClipboardStudioModel.swift`: main state container for history, pack state, focus polling, exports, and settings
- `ClipboardStudioApp/Sources/Services/ClipboardAutomationService.swift`: selection capture, paste automation, and accessibility-dependent actions
- `ClipboardStudioApp/Sources/Services/CurrentContextSnapshotService.swift`: current app, page, window, and selection snapshot capture
- `ClipboardStudioApp/Sources/Services/ContextAssemblyExportService.swift`: Apple Notes and Markdown export flow
- `ClipboardStudioApp/Sources/Services/ContextAssemblyResearchService.swift`: optional OpenAI-backed research enrichment
- `ClipboardStudioApp/Sources/Views/MenuBarView.swift`: main popover UI and action surfaces
- `ClipboardStudioApp/Sources/Views/PackOverlayViews.swift`: live assembly editor and floating-window behavior
- `ClipboardStudioApp/Tests/ContextPackTests.swift`: pack ordering, dedup, focus history, and store separation checks
- `ClipboardStudioApp/Tests/ContextPackFormatterTests.swift`: prompt/export formatting checks

## Working Rules

- Keep the app menu-bar-first. Do not turn it into a full dashboard app.
- Treat clipboard contents and saved focus state as sensitive data.
- Keep the capture loop honest when permissions are missing:
  - Accessibility gates paste automation
  - Apple Events may gate browser or document context capture
- Preserve the current split between model state, capture services, exports, and UI so behavior stays testable.
- Keep OpenAI access optional and sourced from the environment or existing Keychain storage.

## Validation Path

Use the local runner instead of raw commands when possible:

```bash
bash skills/clipboard-studio/scripts/run_clipboard_studio.sh doctor
bash skills/clipboard-studio/scripts/run_clipboard_studio.sh inspect
bash skills/clipboard-studio/scripts/run_clipboard_studio.sh generate
bash skills/clipboard-studio/scripts/run_clipboard_studio.sh typecheck
bash skills/clipboard-studio/scripts/run_clipboard_studio.sh test
```

Use `typecheck` for the fastest source-only sanity pass when you do not need the full test bundle.
Prefer `test` after changes to pack formatting, focus snapshots, exports, or automation flows. Use `run` only when you need the rebuilt menu bar app relaunched locally.
