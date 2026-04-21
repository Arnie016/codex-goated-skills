# Catalog and Audit

This page is the repo's discoverability layer for all installable skills and all downloadable packs.

Machine-readable catalog:
[`catalog/index.json`](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/index.json)

## Snapshot

- Total skills: `64`
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

Audit snapshot for April 12, 2026:

- `64/64` skills include `SKILL.md`
- `64/64` skills include `agents/openai.yaml`
- `64/64` skills include a small SVG icon
- `64/64` skills include a large SVG icon
- `10/10` pack files resolve to valid skill directories
- `51/51` skills are covered by at least one pack

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
| `launch-and-distribution` | Launch rough projects, package them cleanly, and get them ready to share | 8 |
| `productivity-and-workflow` | Workspace setup, document workflows, monitoring, daily reference, and repo-driven skill management | 29 |
| `daily-briefs-and-reference` | Daily context, historical lookup, local pulse, readable export workflows, and market-reading archives | 7 |
| `audience-and-fandom-strategy` | Personality-led audience strategy, fandom analysis, lore pacing, merch, and risk review | 11 |
| `fandom-skill-pack` | Friendly alias for the fandom strategy bundle | 10 |
| `macos-utility-builders` | Mac utility planning and menu bar helper workflows | 12 |
| `app-specific-skills` | Skills tied closely to live local app codebases | 5 |
| `games-and-minecraft` | Minecraft hosting, operations, and skin tooling | 5 |
| `creator-and-fandom-stack` | Creator brand strategy plus launch-ready packaging support | 12 |
| `utility-builder-stack` | A broader Mac utility-building stack across workflow and app surfaces | 8 |

## Full Skill Index

### Launch and Distribution

- [`repo-launch`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/repo-launch): Turn an idea or local project into a clean public repo.
- [`website-drop`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/website-drop): Audit a web app, choose a host, and get it live fast.
- [`brand-kit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/brand-kit): Build lightweight brand assets and launch metadata.
- [`content-pack`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/content-pack): Generate launch-ready messaging, README blurbs, and release copy.
- [`release-ramp`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/release-ramp): Turn a shipping checklist into a compact launch lane.
- [`launch-deck-lift`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/launch-deck-lift): Shape a rough idea into a cleaner launch-deck starter.
- [`package-hygiene-audit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/package-hygiene-audit): Audit release packages, app bundles, notes, and screenshots before shipping.
- [`svg-to-3d-forge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/svg-to-3d-forge): Scaffold SVG assets and turn SVGs into local 3D export formats.

### Productivity and Workflow

- [`workspace-doctor`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/workspace-doctor): Diagnose local workspace readiness, generated catalog freshness, and common setup problems.
- [`branch-brief-bar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/branch-brief-bar): Turn local git state into a review-ready branch handoff.
- [`context-shelf`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/context-shelf): Park the current tab, clipboard snippet, and scratch note so resuming after a task switch is one glance instead of a rebuild.
- [`focus-runway`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/focus-runway): Start the next work block with less setup and less context switching.
- [`front-tab-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/front-tab-relay): Capture the front browser tab and format it for prompts, notes, tickets, or chat handoffs.
- [`excel-range-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/excel-range-relay): Turn a copied Excel selection into clean markdown, CSV, JSON, or prompt-ready context without rebuilding the table by hand.
- [`meeting-link-bridge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/meeting-link-bridge): Turn the current Teams or browser meeting link into a clean join note, email snippet, or quick open action.
- [`screen-snippet-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/screen-snippet-studio): Turn screen snippets into clean prompts, tickets, or handoffs from a menu bar capture flow.
- [`doc-drop-bridge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/doc-drop-bridge): Package notes, markdown, and fragments into share-ready handoff files.
- [`deck-export-bundle`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/deck-export-bundle): Package a current slide deck, notes, and send-ready assets from one compact surface.
- [`download-landing-pad`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/download-landing-pad): Stage fresh downloads with safe rename, reveal, and route actions.
- [`finder-selection-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/finder-selection-relay): Turn the current Finder selection into clean paths and handoff-ready context.
- [`impeccable-cli`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/impeccable-cli): Run deterministic design scans and live anti-pattern overlays for frontend work.
- [`gain-tracker`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/gain-tracker): Connect GitHub, scan repo folders, track daily git gains or broader output gains, and turn them into reminder stories and baseline comparisons.
- [`on-this-day`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/on-this-day): Pull the official Wikimedia On This Day feed into a polished daily history brief or Mac-style day browser.
- [`trading-archive`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/trading-archive): Build a dependable archive of trading and macro articles from public feeds, then surface a reading queue, source health, or native menu bar workflow.
- [`skillbar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/skillbar): Build and refine the SkillBar macOS top-bar skill manager.
- [`clipboard-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/clipboard-studio): Turn scattered clips into one structured prompt and export flow.
- [`repo-ops-lens`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/repo-ops-lens): Turn a GitHub link into a crisp operating brief, risk pass, and next-step suggestion.
- [`patch-pilot`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/patch-pilot): Turn a diff, staged change list, or review thread into a fix brief, risk scan, and next command.
- [`package-hygiene-audit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/package-hygiene-audit): Audit a local package or release folder for ship-readiness.
- [`plist-preflight`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/plist-preflight): Check macOS Info.plist and entitlement metadata before build or signing changes.
- [`reader-mode-bridge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/reader-mode-bridge): Clean saved reading material into deterministic local handoffs.
- [`replay-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/replay-relay): Package clips, screenshots, and quick notes into send-ready replay handoffs.
- [`reply-queue-bar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/reply-queue-bar): Capture copied comments or inbox snippets and queue the next useful reply.
- [`svg-to-3d-forge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/svg-to-3d-forge): Convert SVG work into local 3D export workflows.
- [`network-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio): Install or update a LAN presence monitor with SwiftBar and a dashboard.
- [`dark-pdf-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/dark-pdf-studio): Convert PDFs, docs, and images into dark-background reading PDFs.
- [`deckdrop-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/deckdrop-studio): Shape editable PowerPoint generation flows from mixed-source inputs.
- [`reader-mode-bridge`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/reader-mode-bridge): Keep deterministic reading cleanup close to daily brief and reference workflows.

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
- [`story-arc-board`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/story-arc-board): Capture recurring phrases, symbols, and post ideas before they disappear into notes and comment sprawl.

### macOS Utility Builders

- [`find-my-phone-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/find-my-phone-studio): Shape a realistic Mac phone-finder utility or helper flow.
- [`cursor-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/cursor-studio): Build and refine a cursor-pack planning app for macOS.
- [`folder-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/folder-studio): Build and refine a Finder folder-skin app and icon workflow.
- [`handoff-courier`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/handoff-courier): Move files, snippets, and exports between apps without window gymnastics.
- [`phone-handoff-panel`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/phone-handoff-panel): Keep your phone handoff close with open, locate, and continue actions from the Mac menu bar.
- [`battery-trend-scout`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/battery-trend-scout): Show charge, power source, energy mode, and local drain trends in a calm battery panel.
- [`power-sentry`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/power-sentry): Give a compact at-a-glance read of charging, drain, and energy mode from the menu bar.
- [`chrome-tab-sweeper`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/chrome-tab-sweeper): List overloaded Chrome tabs, group the mess, and close explicit selected batches safely.
- [`download-landing-pad`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/download-landing-pad): Keep fresh browser exports from getting stuck in Downloads.
- [`finder-selection-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/finder-selection-relay): Move selected Finder items into the next app without manual path cleanup.
- [`plist-preflight`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/plist-preflight): Check app metadata before signing, release, or Info.plist edits.
- [`replay-relay`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/replay-relay): Keep game clips and screenshots moving through a compact share lane.

### App-Specific Skills

- [`telebar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/telebar): Build and run the TeleBar Telegram and AI menu bar app.
- [`flight-scout`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/flight-scout): Build and run the Flight Scout macOS menu bar app.
- [`on-this-day-bar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/on-this-day-bar): Build and run the On This Day Bar macOS menu bar app.
- [`vibe-bluetooth`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/vibe-bluetooth): Build, run, and troubleshoot the VibeWidget macOS app and widget.
- [`wifi-watchtower`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/wifi-watchtower): Build and run the WiFi Watchtower macOS menu bar app.

### Games and Minecraft

- [`minecraft-essentials`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-essentials): Install, upgrade, back up, and troubleshoot Minecraft Java servers.
- [`minecraft-skin-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-skin-studio): Draft, preview, and register Minecraft Java skins.
- [`session-arcade`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/session-arcade): Help launch the next game session or console handoff without extra setup loops.
- [`minefield-menubar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minefield-menubar): Build a playable Minesweeper-style menu bar game.
- [`minesweeper-menubar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minesweeper-menubar): Build and refine a Swift menu bar Minesweeper app.
