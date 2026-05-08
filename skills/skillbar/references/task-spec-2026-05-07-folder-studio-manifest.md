# Task Spec: Folder Studio Manifest Metadata

## Goal

Add a first-class `manifest.json` for the existing `folder-studio` skill so SkillBar and the generated catalog can use manifest-driven metadata, icons, and a direct system symbol instead of relying only on OpenAI interface fallback fields.

## Scope

- Keep the existing `folder-studio` skill behavior, prompt, assets, and pack membership unchanged.
- Mirror the current `SKILL.md` and `agents/openai.yaml` metadata where it already works.
- Add catalog-facing audience, tags, detail lines, docs paths, file hints, and `system_symbol` metadata.

## Validation

- `jq` the new manifest.
- Regenerate and verify the skill catalog.
- Run the repo skill-market sync and audit.
- Run SkillBar catalog/audit checks plus the standard typecheck and smoke checks for this automation run.
