# Collections

Pack files live in this folder so the repo can group installable skills by use case without breaking the flat `skills/<skill-id>` layout.

Use the CLI:

```bash
codex-goated pack list
codex-goated pack show creator-and-fandom-stack
codex-goated pack install launch-and-distribution
codex-goated pack install fandom-skill-pack
codex-goated search fandom
codex-goated audit
```

Raw script fallback:

```bash
bash scripts/install-pack.sh creator-and-fandom-stack
```

## Pack Index

| Pack | What it is for | Skill count |
| --- | --- | --- |
| `launch-and-distribution` | Turning rough projects into launch-ready, public packages | 4 |
| `productivity-and-workflow` | Workspace setup, document workflows, local tooling, and catalog management | 6 |
| `audience-and-fandom-strategy` | Personality-led audience strategy, fandom analysis, rituals, merch, and narrative risk work | 10 |
| `fandom-skill-pack` | Friendly alias for the fandom strategy bundle | 10 |
| `macos-utility-builders` | Menu bar utilities, Mac helpers, and focused utility-app shaping | 3 |
| `app-specific-skills` | Repo-specific app implementation skills | 2 |
| `games-and-minecraft` | Minecraft operations and customization | 2 |
| `creator-and-fandom-stack` | Creator brand strategy plus launch/packaging support | 12 |
| `utility-builder-stack` | A broader Mac utility-building bundle across workflow and app surfaces | 8 |

## Quick Install

| Use case | Command |
| --- | --- |
| Ship a project or repo | `codex-goated pack install launch-and-distribution` |
| Build a creator or fandom strategy stack | `codex-goated pack install creator-and-fandom-stack` |
| Install only the audience strategy suite | `codex-goated pack install fandom-skill-pack` |
| Build focused Mac helpers and menu bar utilities | `codex-goated pack install macos-utility-builders` |
| Grab a broader utility-building setup | `codex-goated pack install utility-builder-stack` |
| Pull the workspace and monitoring toolkit | `codex-goated pack install productivity-and-workflow` |

## Maintenance Notes

- Pack files are simple text lists with optional comment metadata.
- `# title:` and `# summary:` lines drive CLI discoverability.
- Every pack should reference only existing directories under `skills/`.
- Every skill in the repo should belong to at least one pack.
- The generated machine-readable index lives at [`catalog/index.json`](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/index.json).
