# Collections

Pack files live in this folder so the repo can group installable skills by use case without breaking the flat `skills/<skill-id>` layout.

Use the CLI:

```bash
codex-goated pack list
codex-goated pack show creator-and-fandom-stack
codex-goated pack install launch-and-distribution
codex-goated pack install fandom-skill-pack
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

## Maintenance Notes

- Pack files are simple text lists with optional comment metadata.
- `# title:` and `# summary:` lines drive CLI discoverability.
- Every pack should reference only existing directories under `skills/`.
- Every skill in the repo should belong to at least one pack.
