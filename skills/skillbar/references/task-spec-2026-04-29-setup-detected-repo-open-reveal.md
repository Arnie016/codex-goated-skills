## Task Spec

- Problem: Setup shows a detected repo candidate, but the quick-setup controls only expose open and reveal actions for the currently selected valid repo. When the saved repo path is invalid, users cannot inspect the detected candidate before adopting it.
- Scope: Keep the change limited to SkillBar setup UX. Add model helpers for the quick-setup repo target, update the setup buttons to use that target, and add focused tests for the new labels and fallback path.
- Guardrails: Preserve the existing install/update flow through `bin/codex-goated`, keep repo resolution local-first, and avoid changing unrelated catalog or icon behavior.
