# Collections

Pack files live in this folder so the repo can group installable skills by use case without breaking the flat `skills/<skill-id>` layout.

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
| `launch-and-distribution` | Turning rough projects into launch-ready, public packages | 7 |
| `productivity-and-workflow` | Workspace setup, workflow handoffs, document flows, local tooling, daily reference, and catalog management | 20 |
| `daily-briefs-and-reference` | Daily context, historical lookup, market-reading archives, local pulse, and readable export workflows | 6 |
| `audience-and-fandom-strategy` | Personality-led audience strategy, fandom analysis, rituals, merch, and narrative risk work | 11 |
| `fandom-skill-pack` | Friendly alias for the fandom strategy bundle | 11 |
| `macos-utility-builders` | Menu bar utilities, Mac helpers, and focused utility-app shaping | 6 |
| `app-specific-skills` | Repo-specific app implementation skills | 6 |
| `games-and-minecraft` | Console helpers plus Minecraft operations and customization | 4 |
| `creator-and-fandom-stack` | Creator brand strategy plus launch/packaging support | 13 |
| `utility-builder-stack` | A broader Mac utility-building bundle across workflow and app surfaces | 17 |

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

Primary browse lanes:

- `launch-and-distribution`, `productivity-and-workflow`, `audience-and-fandom-strategy`, `macos-utility-builders`, `app-specific-skills`, and `games-and-minecraft`

Alias and stack packs:

- `daily-briefs-and-reference`, `fandom-skill-pack`, `creator-and-fandom-stack`, and `utility-builder-stack`

## Maintenance Notes

- Pack files are simple text lists with optional comment metadata.
- `# title:` and `# summary:` lines drive CLI discoverability.
- The six primary packs also define the repo's top-level browse categories and manifest `category` values.
- Every pack should reference only existing directories under `skills/`.
- Every skill in the repo should belong to at least one pack.
- The generated machine-readable index lives at [`catalog/index.json`](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/index.json).
