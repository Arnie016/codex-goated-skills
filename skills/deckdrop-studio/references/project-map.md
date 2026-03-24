# DeckDrop Project Map

Default workspace: use the current repo when it contains `DeckDropApp` and `project.yml`. Otherwise, pass `--workspace /path/to/workspace` to the runner.

## Targets

- `DeckDrop`: macOS menu bar app for staged intake, draft review, and export
- `DeckDropTests`: unit and pipeline regression tests
- `VibeWidgetCore`: shared framework reused only for common pieces such as secure secret storage

## Main Files

- `project.yml`: XcodeGen spec for the DeckDrop target, resources, and tests
- `DeckDropApp/Sources/App/DeckDropAppModel.swift`: staged input state, workflow state, and build orchestration
- `DeckDropApp/Sources/App/DeckDropModels.swift`: source, section, slide, artifact, and manifest models
- `DeckDropApp/Sources/Services/ContextBundleService.swift`: source validation, staging, support-file summarization, and workspace setup
- `DeckDropApp/Sources/Services/PDFExtractionService.swift`: primary-source extraction and section fallback logic
- `DeckDropApp/Sources/Services/DeckPlanningService.swift`: slide plan generation, extract-everything mode, and review-ready draft construction
- `DeckDropApp/Sources/Services/PPTXExportService.swift`: manifest, editable deck, split-deck, zip, and preview export
- `DeckDropApp/Sources/Views/DeckDropMenuBarView.swift`: compact menu bar workflow, staged counts, and action surface
- `DeckDropApp/Sources/Views/DeckDropDraftEditorView.swift`: human-in-the-loop draft editor before export
- `DeckDropApp/Resources/scripts/`: Python helpers for source extraction, support context, and preview montage generation
- `DeckDropApp/DeckWriter/`: Node and PptxGenJS export writer

## Pipeline Map

1. Intake and validation
   `DeckDropMenuBarView` -> `DeckDropAppModel` -> `ContextBundleService`
2. Primary extraction
   `DeckDropAppModel` -> `PDFExtractionService` -> Python extraction scripts
3. Draft planning
   `DeckPlanningService` builds sections and editable slides, with source fidelity first
4. Human review
   `DeckDropDraftEditorView` lets the user adjust text before export
5. Export
   `PPTXExportService` and `DeckWriter` produce `.pptx`, manifests, split decks, zips, and preview artifacts

## Source And Artifact Contract

- Primary source kinds:
  - PDF
  - document
  - presentation
  - image
- Support context:
  - documents
  - images
- High-signal staged metrics:
  - pages or slides
  - words
  - estimated tokens
  - support document count
  - support image count
  - warnings
- Export bundle should keep the editable deck first, plus manifest and optional split or preview artifacts.

## Run And Build Notes

- Use the runner script first:
  `bash scripts/run_deckdrop_studio.sh <command>`
- If the app lives outside the current repo, use:
  `bash scripts/run_deckdrop_studio.sh --workspace /path/to/workspace <command>`
- `generate` uses `xcodegen`.
- `open` launches `VibeWidget.xcodeproj`.
- `build` and `test` use the `DeckDrop` scheme on macOS.
- The Node writer depends on `DeckDropApp/DeckWriter/package.json`.
- The extraction pipeline depends on `python3` plus the workspace's bundled scripts.

## Constraints

- Keep the workflow review-first, not export-only.
- Preserve the primary source as the source of truth even when support context exists.
- Keep slide text editable in PowerPoint output.
- If output contracts change, update Swift models, Python scripts, and Node export code together.
