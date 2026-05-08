# Deckdrop Studio Manifest Pass

## Goal

Make Deckdrop Studio's SkillBar and catalog presentation manifest-driven so its editable slide workflow has stable metadata, icon paths, pack-facing detail copy, and local-first safety framing.

## Scope

- Add `skills/deckdrop-studio/manifest.json`.
- Reuse the existing small and large Deckdrop Studio SVG assets.
- Preserve existing pack membership and generated catalog flow.
- Avoid touching protected DeckDrop app source, project settings, signing files, or export pipeline code.

## Ownership Notes

- Primary team: Documents, Decks, And Creative Export.
- Closest adjacent skill: `deck-export-bundle`; Deckdrop Studio remains materially different because it builds and reviews editable draft decks from mixed sources, while Deck Export Bundle packages an already-current deck and notes for handoff.
- Safety posture: local explicit workspaces and user-selected source files, no hidden remote sync, no broad account-token persistence, and no export without a visible review workflow.

## Verification Plan

- `jq empty skills/deckdrop-studio/manifest.json`
- `python scripts/build_skill_market_index.py`
- `python scripts/skill_market_loop.py sync`
- `python scripts/skill_market_loop.py audit`
- `bash scripts/run_skillbar.sh catalog-check`
- `bash scripts/run_skillbar.sh audit`
- `bash scripts/run_skillbar.sh typecheck`
- `bash scripts/run_skillbar.sh smoke-install skillbar`
- `bash scripts/run_skillbar.sh smoke-update skillbar`
