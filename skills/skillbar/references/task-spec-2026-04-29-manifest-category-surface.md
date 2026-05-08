## Task Spec

- Problem: SkillBar already decodes manifest metadata, but the visible category chips and category search still use the coarse internal fallback bucket instead of the manifest category users curate in `skills/*/manifest.json`.
- Goal: Keep the internal fallback bucket for icons and grouping, while surfacing the manifest category label in the menu-bar UI and search paths.
- Scope: `SkillBarModels.swift`, `SkillCatalogService.swift`, `SkillBarModel.swift`, `MenuBarView.swift`, and parser tests only.
- Guardrails: Preserve manifest-first parsing, do not change install/update wiring, and keep the fallback bucket available for symbol selection when a skill has no asset icon.
