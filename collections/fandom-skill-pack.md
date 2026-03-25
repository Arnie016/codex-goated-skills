# Fandom Skill Pack

This collection groups the repo's audience, fandom, and personality-led brand strategy skills without changing the flat installable structure under `skills/`.

## Included Skills

- `fan-canon-miner`
- `comment-pulse-board`
- `clip-to-canon-finder`
- `iconography-lab`
- `ritual-engine`
- `parasocial-studio`
- `lore-drop-planner`
- `inner-circle-director`
- `myth-merch-studio`
- `reputation-heatmap`

## Why This Collection Exists

- Keeps the installable skill directories flat so the current repo tooling and installers keep working.
- Gives the fandom pack one source-of-truth list for bundle installs and repo docs.
- Makes the audience strategy skills feel like a maintained suite instead of a random cluster of folders.

## Maintenance Rules

1. Keep each installable package at `skills/<skill-id>/`.
2. When adding or removing a fandom skill, update this file and `collections/fandom-skill-pack.txt` together.
3. Keep the README's `Audience and Fandom Strategy` section aligned with this collection.
4. If a future catalog app or manager adds first-class collection support, point it at `collections/fandom-skill-pack.txt` instead of duplicating the list again.

## Install The Whole Pack

```bash
bash scripts/install-fandom-pack.sh
```
