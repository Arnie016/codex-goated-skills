# Catalog and Audit

This page is the repo's discoverability layer for all installable skills and all downloadable packs.

Machine-readable catalog:
[`catalog/index.json`](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/index.json)

## Snapshot

- Total skills: `54`
- Total packs: `10`
- Main pack folder: [`collections/`](https://github.com/Arnie016/codex-goated-skills/tree/main/collections)
- Main install CLI: [`bin/codex-goated`](https://github.com/Arnie016/codex-goated-skills/blob/main/bin/codex-goated)

Quick commands:

```bash
codex-goated search history
codex-goated pack list
codex-goated pack show daily-briefs-and-reference
codex-goated pack show launch-and-distribution
codex-goated pack install creator-and-fandom-stack
codex-goated catalog check
codex-goated audit
```

## Audit Status

Audit snapshot for April 16, 2026:

- `54/54` skills include `manifest.json`
- `54/54` skills include `SKILL.md`
- `54/54` skills include `agents/openai.yaml`
- `54/54` skills include a small SVG icon
- `54/54` skills include a large SVG icon
- `10/10` pack files resolve to valid skill directories
- `54/54` skills are covered by at least one pack

Run the live audit locally:

```bash
python3 scripts/sync-skill-manifests.py --check
codex-goated catalog build
codex-goated catalog check
codex-goated audit
bash scripts/audit-catalog.sh
```

Generated index:

- `catalog/index.json` is built from `skills/*/manifest.json`, skill frontmatter, `agents/openai.yaml`, and pack files.
- Regenerate it with `codex-goated catalog build`.
- Validate freshness with `codex-goated catalog check`.

Continuous audit:

- GitHub Actions runs [`.github/workflows/catalog-audit.yml`](https://github.com/Arnie016/codex-goated-skills/blob/main/.github/workflows/catalog-audit.yml) on pushes and pull requests that touch skills, collections, scripts, catalog docs, or the main CLI.

## Pack Index

| Pack | Purpose | Skill count |
| --- | --- | --- |
| `launch-and-distribution` | Launch rough projects, package them cleanly, and get them ready to share | 7 |
| `productivity-and-workflow` | Workspace setup, workflow handoffs, document flows, monitoring, daily reference, and repo-driven skill management | 20 |
| `daily-briefs-and-reference` | Daily context, historical lookup, local pulse, readable export workflows, and market-reading archives | 6 |
| `audience-and-fandom-strategy` | Personality-led audience strategy, fandom analysis, lore pacing, merch, and risk review | 11 |
| `fandom-skill-pack` | Friendly alias for the fandom strategy bundle | 11 |
| `macos-utility-builders` | Mac utility planning and menu bar helper workflows | 6 |
| `app-specific-skills` | Skills tied closely to live local app codebases | 6 |
| `games-and-minecraft` | Console helpers plus Minecraft hosting, operations, and skin tooling | 4 |
| `creator-and-fandom-stack` | Creator brand strategy plus launch-ready packaging support | 13 |
| `utility-builder-stack` | A broader Mac utility-building stack across workflow and app surfaces | 17 |

## Full Skill Index

### Launch and Distribution

- [`repo-launch`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/repo-launch): Turn an idea or local project into a clean public repo.
- [`website-drop`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/website-drop): Audit a web app, choose a host, and get it live fast.
- [`brand-kit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/brand-kit): Build lightweight brand assets and launch metadata.
- [`content-pack`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/content-pack): Generate launch-ready messaging, README blurbs, and release copy.
- [`release-ramp`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/release-ramp): Turn a shipping checklist into a clean launch lane.
- [`repo-ops-lens`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/repo-ops-lens): Reduce a GitHub repo to a crisp operating brief, risk pass, and next-step suggestion.
- [`launch-deck-lift`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/launch-deck-lift): Turn a rough idea into a cleaner launch deck starter.

### Productivity and Workflow

Workflow skills are grouped into smaller browse lanes here on purpose so new additions land in the main catalog instead of a separate recent bucket.

#### Workspace and Daily Context

- [`workspace-doctor`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/workspace-doctor): Diagnose local workspace readiness, generated catalog freshness, and common setup problems.
- [`gain-tracker`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/gain-tracker): Connect GitHub, scan repo folders, track daily git gains or broader output gains, and turn them into reminder stories and baseline comparisons.
- [`on-this-day`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/on-this-day): Pull the official Wikimedia On This Day feed into a polished daily history brief or Mac-style day browser.
- [`trading-archive`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/trading-archive): Build a dependable archive of trading and macro articles from public feeds, then surface a reading queue, source health, or native menu bar workflow.
- [`skillbar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/skillbar): Build and refine the SkillBar macOS top-bar skill manager.

#### Workflow Handoffs and Automation

- [`context-shelf`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/context-shelf): Park the current tab, clipboard snippet, and scratch note so resuming after a task switch is one glance instead of a rebuild.
- [`project-hail-mary`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/project-hail-mary): Kick off a realistic crunch-mode rescue launcher with a hype track, critical work surfaces, and a countdown.
- [`focus-runway`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/focus-runway): Start the next work block with less setup and less context switching.
- [`front-tab-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/front-tab-relay): Capture the front browser tab and format it for prompts, notes, tickets, or chat handoffs.
- [`meeting-link-bridge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/meeting-link-bridge): Turn the current Teams or browser meeting link into a clean join note, email snippet, or fast open action.
- [`excel-range-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/excel-range-relay): Turn the copied Excel selection into clean markdown, CSV, JSON, or prompt context without rebuilding the table by hand.
- [`screen-snippet-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/screen-snippet-studio): Turn screen snippets into prompts, tickets, and handoff artifacts.
- [`doc-drop-bridge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/doc-drop-bridge): Turn notes, markdown, and fragments into share-ready handoff files.
- [`patch-pilot`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/patch-pilot): Turn a patch or file list into a crisp fix brief, risk scan, and next command.

#### Document and Local Utility Flows

- [`clipboard-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/clipboard-studio): Turn scattered clips into one structured prompt and export flow.
- [`network-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio): Install or update a LAN presence monitor with SwiftBar and a dashboard.
- [`dark-pdf-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/dark-pdf-studio): Convert PDFs, docs, and images into dark-background reading PDFs.
- [`deckdrop-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/deckdrop-studio): Shape editable PowerPoint generation flows from mixed-source inputs.
- [`battery-trend-scout`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/battery-trend-scout): Build a polished battery utility with charge, power source, energy mode, and drain trends.
- [`power-sentry`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/power-sentry): Keep battery drain, charging, and energy mode visible at a glance.

### Audience and Narrative

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
- [`story-arc-board`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/story-arc-board): Catch recurring hooks from notes, captions, and comments before they disappear into app sprawl.

### macOS Utility Builders

- [`find-my-phone-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/find-my-phone-studio): Shape a realistic Mac phone-finder utility or helper flow.
- [`cursor-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/cursor-studio): Build and refine a cursor-pack planning app for macOS.
- [`folder-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/folder-studio): Build and refine a Finder folder-skin app and icon workflow.
- [`handoff-courier`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/handoff-courier): Move files, snippets, and exports between apps without window gymnastics.
- [`phone-handoff-panel`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/phone-handoff-panel): Keep a compact phone handoff surface close from the Mac menu bar.
- [`chrome-tab-sweeper`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/chrome-tab-sweeper): Review overloaded Chrome tabs and close selected tab batches safely.

### App-Specific Skills

- [`telebar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/telebar): Build and run the TeleBar Telegram and AI menu bar app.
- [`flight-scout`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/flight-scout): Build and run the Flight Scout macOS menu bar app.
- [`on-this-day-bar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/on-this-day-bar): Build and run the On This Day Bar macOS menu bar app.
- [`vibe-bluetooth`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/vibe-bluetooth): Build, run, and troubleshoot the VibeWidget macOS app and widget.
- [`wifi-watchtower`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/wifi-watchtower): Build and run the WiFi Watchtower macOS menu bar app.
- [`framecrawler`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/framecrawler): Build and extend the FrameCrawler prompt-to-Blender SceneSpec workflow and handoff surface.

### Games and Consoles

- [`xbox-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/xbox-studio): Build and run a controller-first macOS Xbox helper for Bluetooth readiness, pairing, cloud gaming, Remote Play, captures, and account flows.
- [`minecraft-essentials`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-essentials): Install, upgrade, back up, and troubleshoot Minecraft Java servers.
- [`minecraft-skin-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-skin-studio): Draft, preview, and register Minecraft Java skins.
- [`session-arcade`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/session-arcade): Keep game sessions, cloud gaming, and quick console handoffs within a few clicks.
