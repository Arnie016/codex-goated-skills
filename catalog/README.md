# Catalog and Audit

This page is the repo's discoverability layer for all installable skills and all downloadable packs.

Machine-readable catalog:
[`catalog/index.json`](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/index.json)

## Snapshot

- Total skills: `27`
- Total packs: `9`
- Main pack folder: [`collections/`](https://github.com/Arnie016/codex-goated-skills/tree/main/collections)
- Main install CLI: [`bin/codex-goated`](https://github.com/Arnie016/codex-goated-skills/blob/main/bin/codex-goated)

Quick commands:

```bash
codex-goated search fandom
codex-goated pack list
codex-goated pack show launch-and-distribution
codex-goated pack install creator-and-fandom-stack
codex-goated catalog check
codex-goated audit
```

## Audit Status

Audit snapshot for March 26, 2026:

- `27/27` skills include `SKILL.md`
- `27/27` skills include `agents/openai.yaml`
- `27/27` skills include a small SVG icon
- `27/27` skills include a large SVG icon
- `9/9` pack files resolve to valid skill directories
- `27/27` skills are covered by at least one pack

Run the live audit locally:

```bash
codex-goated catalog build
codex-goated catalog check
codex-goated audit
bash scripts/audit-catalog.sh
```

Generated index:

- `catalog/index.json` is built from the skill frontmatter, `agents/openai.yaml`, and pack files.
- Regenerate it with `codex-goated catalog build`.
- Validate freshness with `codex-goated catalog check`.

Continuous audit:

- GitHub Actions runs [`.github/workflows/catalog-audit.yml`](https://github.com/Arnie016/codex-goated-skills/blob/main/.github/workflows/catalog-audit.yml) on pushes and pull requests that touch skills, collections, scripts, catalog docs, or the main CLI.

## Pack Index

| Pack | Purpose | Skill count |
| --- | --- | --- |
| `launch-and-distribution` | Launch rough projects, package them cleanly, and get them ready to share | 4 |
| `productivity-and-workflow` | Workspace setup, document workflows, monitoring, and repo-driven skill management | 6 |
| `audience-and-fandom-strategy` | Personality-led audience strategy, fandom analysis, lore pacing, merch, and risk review | 10 |
| `fandom-skill-pack` | Friendly alias for the fandom strategy bundle | 10 |
| `macos-utility-builders` | Mac utility planning and menu bar helper workflows | 3 |
| `app-specific-skills` | Skills tied closely to live local app codebases | 2 |
| `games-and-minecraft` | Minecraft hosting, operations, and skin tooling | 2 |
| `creator-and-fandom-stack` | Creator brand strategy plus launch-ready packaging support | 12 |
| `utility-builder-stack` | A broader Mac utility-building stack across workflow and app surfaces | 8 |

## Full Skill Index

### Launch and Distribution

- [`repo-launch`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/repo-launch): Turn an idea or local project into a clean public repo.
- [`website-drop`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/website-drop): Audit a web app, choose a host, and get it live fast.
- [`brand-kit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/brand-kit): Build lightweight brand assets and launch metadata.
- [`content-pack`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/content-pack): Generate launch-ready messaging, README blurbs, and release copy.

### Productivity and Workflow

- [`workspace-doctor`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/workspace-doctor): Diagnose local setup blockers and workspace readiness issues.
- [`skillbar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/skillbar): Build and refine the SkillBar macOS top-bar skill manager.
- [`clipboard-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/clipboard-studio): Turn scattered clips into one structured prompt and export flow.
- [`network-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio): Install or update a LAN presence monitor with SwiftBar and a dashboard.
- [`dark-pdf-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/dark-pdf-studio): Convert PDFs, docs, and images into dark-background reading PDFs.
- [`deckdrop-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/deckdrop-studio): Shape editable PowerPoint generation flows from mixed-source inputs.

### Audience and Fandom Strategy

- [`fan-canon-miner`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/fan-canon-miner): Mine comments, interviews, captions, and chatter into a canon map.
- [`comment-pulse-board`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/comment-pulse-board): Cluster obsession points, recurring questions, sentiment shifts, and backlash signals.
- [`clip-to-canon-finder`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/clip-to-canon-finder): Score clips, transcripts, and reactions to find repeatable canon moments.
- [`iconography-lab`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/iconography-lab): Define the recognizable visual and verbal codes of a public figure or creator.
- [`ritual-engine`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/ritual-engine): Design repeatable fan rituals, loops, and recurring participation formats.
- [`parasocial-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/parasocial-studio): Shape safe closeness mechanics and recurring relationship touchpoints.
- [`lore-drop-planner`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/lore-drop-planner): Plan episodic reveals, callbacks, teasers, and payoff arcs.
- [`inner-circle-director`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/inner-circle-director): Structure tiered access, VIP mechanics, and premium community experiences.
- [`myth-merch-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/myth-merch-studio): Turn fandom canon into merch, collectible, and limited-drop concepts.
- [`reputation-heatmap`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/reputation-heatmap): Separate healthy mystique from rumor, overreach, parasocial risk, or brand harm.

### macOS Utility Builders

- [`find-my-phone-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/find-my-phone-studio): Shape a realistic Mac phone-finder utility or helper flow.
- [`cursor-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/cursor-studio): Build and refine a cursor-pack planning app for macOS.
- [`folder-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/folder-studio): Build and refine a Finder folder-skin app and icon workflow.

### App-Specific Skills

- [`telebar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/telebar): Build and run the TeleBar Telegram and AI menu bar app.
- [`vibe-bluetooth`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/vibe-bluetooth): Build, run, and troubleshoot the VibeWidget macOS app and widget.

### Games and Minecraft

- [`minecraft-essentials`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-essentials): Install, upgrade, back up, and troubleshoot Minecraft Java servers.
- [`minecraft-skin-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-skin-studio): Draft, preview, and register Minecraft Java skins.
