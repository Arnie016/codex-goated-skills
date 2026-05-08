# Collections

Pack files live in this folder so the repo can group installable skills by use case without breaking the flat `skills/<skill-id>` layout.

For ownership and skill-factory gap review, use [`SKILL_TEAMS.md`](SKILL_TEAMS.md). For the newer macOS Icon Bars subset, use [`icon-bar-skill-categories.md`](icon-bar-skill-categories.md). Packs stay user-facing install bundles; teams are the maintenance map.

Use the CLI:

```bash
codex-goated pack list
codex-goated pack show creator-and-fandom-stack
codex-goated pack show daily-briefs-and-reference
codex-goated pack install launch-and-distribution
codex-goated pack install fandom-skill-pack
codex-goated search history
codex-goated audit
```

Raw script fallback:

```bash
bash scripts/install-pack.sh creator-and-fandom-stack
```

## Pack Index

| Pack | What it is for | Skill count |
| --- | --- | --- |
| `launch-and-distribution` | Turning rough projects into launch-ready, public packages | 8 |
| `productivity-and-workflow` | Workspace setup, document workflows, local tooling, daily reference, and catalog management | 29 |
| `daily-briefs-and-reference` | Daily context, historical lookup, market-reading archives, local pulse, and readable export workflows | 7 |
| `audience-and-fandom-strategy` | Personality-led audience strategy, fandom analysis, rituals, merch, and narrative risk work | 11 |
| `fandom-skill-pack` | Friendly alias for the fandom strategy bundle | 10 |
| `macos-utility-builders` | Menu bar utilities, Mac helpers, and focused utility-app shaping | 12 |
| `app-specific-skills` | Repo-specific app implementation skills | 5 |
| `games-and-minecraft` | Minecraft operations and customization | 5 |
| `creator-and-fandom-stack` | Creator brand strategy plus launch/packaging support | 12 |
| `utility-builder-stack` | A broader Mac utility-building bundle across workflow and app surfaces | 8 |

## Quick Install

| Use case | Command |
| --- | --- |
| Ship a project or repo | `codex-goated pack install launch-and-distribution` |
| Build a creator or fandom strategy stack | `codex-goated pack install creator-and-fandom-stack` |
| Install only the audience strategy suite | `codex-goated pack install fandom-skill-pack` |
| Build a daily ritual stack for facts, pulse, and market-reading archives | `codex-goated pack install daily-briefs-and-reference` |
| Build focused Mac helpers and menu bar utilities | `codex-goated pack install macos-utility-builders` |
| Grab a broader utility-building setup | `codex-goated pack install utility-builder-stack` |
| Pull the workspace and monitoring toolkit | `codex-goated pack install productivity-and-workflow` |

## Maintenance Notes

- Pack files are simple text lists with optional comment metadata.
- `# title:` and `# summary:` lines drive CLI discoverability.
- Every pack should reference only existing directories under `skills/`.
- Every skill in the repo should belong to at least one pack.
- The generated machine-readable index lives at [`catalog/index.json`](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/index.json).
