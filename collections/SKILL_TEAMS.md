# Skill Teams

This map assigns every surfaced skill in `catalog/index.json` to one primary product team. Packs remain the install and browse layer; teams are for ownership, gap review, and deciding whether a new macOS Icon Bars skill is actually useful.

Source checked: local `catalog/index.json` and the GitHub `codex/macos-icon-bars-plugin` README on 2026-05-06.

## Team Rules

- Keep each skill in exactly one primary team here.
- Use existing packs for cross-listing; do not duplicate team rows for secondary use cases.
- Add a new skill only when it solves a concrete local-first macOS workflow gap that is not already covered by a nearby skill.
- New icon-bar skills must ship with useful metadata, small readable icons, pack coverage, catalog regeneration, and audit verification.

## SkillBar And Catalog Platform

Owns SkillBar, catalog health, repo diagnostics, release/package checks, and developer-facing operating loops.

| Skill | Role |
| --- | --- |
| `skillbar` | macOS manager for the skill catalog, packs, install state, icons, and update flows. |
| `workspace-doctor` | Repo and toolchain diagnostics for finding the next useful local command. |
| `repo-ops-lens` | GitHub/repo operating brief and risk scan. |
| `branch-brief-bar` | Local branch status and review-ready handoff brief. |
| `patch-pilot` | Patch and diff triage surface. |
| `impeccable-cli` | Deterministic frontend design audit wrapper. |
| `plist-preflight` | macOS app metadata, plist, entitlement, and build preflight checks. |
| `package-hygiene-audit` | Local release package, screenshot, and notes audit before shipping. |

## macOS System And Device Utilities

Owns focused menu-bar utilities for device state, Mac control surfaces, Finder/browser cleanup, and system readability.

| Skill | Role |
| --- | --- |
| `battery-trend-scout` | Battery, charging, power-source, and drain trend panel. |
| `power-sentry` | Battery and energy mode watch surface. |
| `network-studio` | LAN monitor and SwiftBar network workspace. |
| `wifi-watchtower` | Wi-Fi trust and nearby scan monitor. |
| `find-my-phone-studio` | Phone locate/ring/call/provider handoff utility. |
| `phone-handoff-panel` | Mac-to-phone jump-start and handoff panel. |
| `vibe-bluetooth` | VibeWidget and Bluetooth-adjacent app workflow. |
| `chrome-tab-sweeper` | Chrome tab overload inspection and cleanup. |
| `download-landing-pad` | Downloads staging, rename, reveal, and route surface. |
| `cursor-studio` | Cursor pack planning and export workflow. |
| `folder-studio` | Finder folder skin and icon workflow. |

## Workflow Handoffs And Capture

Owns cross-app capture, clipboard, prompt-context, meeting, file, and communication handoffs.

| Skill | Role |
| --- | --- |
| `context-shelf` | Park current tab, clipboard snippet, and scratch note for task resumption. |
| `clipboard-studio` | Context Assembly app for structured prompt, note, and markdown exports. |
| `handoff-courier` | File, snippet, and export courier between apps. |
| `finder-selection-relay` | Finder selection to clean paths and handoff-ready context. |
| `front-tab-relay` | Front browser tab title/URL relay into prompts, notes, or tickets. |
| `meeting-link-bridge` | Teams/browser meeting link cleanup and handoff. |
| `excel-range-relay` | Excel range relay into markdown, CSV, JSON, and prompt context. |
| `focus-runway` | Focus-block launcher and context-switch reducer. |
| `reply-queue-bar` | Comment/inbox snippet triage and reply queue. |
| `screen-snippet-studio` | Screen clipping into prompts, tickets, or handoffs. |
| `replay-relay` | Game clip, screenshot, and quick-note share lane. |
| `project-hail-mary` | Deadline rescue launcher, countdown, and copied-status workflow. |

## Documents, Decks, And Creative Export

Owns document cleanup, decks, reader outputs, launch presentation helpers, and local creative conversion flows.

| Skill | Role |
| --- | --- |
| `dark-pdf-studio` | Dark-background PDF, document, and image conversion. |
| `deckdrop-studio` | Editable slide workflows for mixed-source decks. |
| `deck-export-bundle` | Deck, speaker notes, and send-ready asset packaging. |
| `doc-drop-bridge` | Notes, markdown, and fragments to share-ready handoff files. |
| `reader-mode-bridge` | HTML/article/PDF excerpt cleanup with preserved metadata. |
| `launch-deck-lift` | Rough launch idea to clean deck starter. |
| `svg-to-3d-forge` | SVG asset scaffolding and local 3D export handoff. |
| `framecrawler` | Prompt-to-Blender SceneSpec and watched-file creative handoff. |

## Launch And Distribution

Owns public launch readiness, packaging copy, brand polish, and shipping lanes.

| Skill | Role |
| --- | --- |
| `repo-launch` | Rough project to clean public repo. |
| `website-drop` | Web app audit, hosting choice, and launch flow. |
| `brand-kit` | Lightweight brand assets and launch metadata. |
| `content-pack` | README, launch copy, and paste-ready project assets. |
| `release-ramp` | Release checklist and launch lane. |

## Creator And Fandom Strategy

Owns audience intelligence, fandom canon, rituals, narrative risk, merch concepts, and community strategy.

| Skill | Role |
| --- | --- |
| `fan-canon-miner` | Public or authorized fan chatter to grounded canon map. |
| `comment-pulse-board` | Audience chatter clustering and pulse digest. |
| `clip-to-canon-finder` | Clip/transcript scoring for repeat canon moments. |
| `iconography-lab` | Visual and verbal codes for personality-led brands. |
| `ritual-engine` | Repeatable fan rituals, loops, naming systems, and recurring formats. |
| `parasocial-studio` | Safe closeness mechanics and relationship touchpoints. |
| `lore-drop-planner` | Teasers, callbacks, reveals, and payoff arcs. |
| `inner-circle-director` | Tiered access and VIP community structures. |
| `myth-merch-studio` | Lore, symbols, and phrases to merch briefs. |
| `reputation-heatmap` | Mystique, rumor, overreach, parasocial, and brand-harm risk. |
| `story-arc-board` | Repeated hooks from notes, captions, and comments. |

## Games And Play

Owns game helpers, Minecraft workflows, quick menu-bar games, and session launch surfaces.

| Skill | Role |
| --- | --- |
| `minecraft-essentials` | Minecraft Java server operations and troubleshooting. |
| `minecraft-skin-studio` | Minecraft skin drafting, previewing, and app workflow. |
| `minefield-menubar` | Minesweeper-style macOS menu-bar puzzle. |
| `minesweeper-menubar` | Compact native Minesweeper menu-bar concept. |
| `session-arcade` | Game session, cloud gaming, and console handoff launcher. |
| `xbox-studio` | Xbox controller, cloud gaming, Remote Play, and capture handoff helper. |

## Daily Context And App-Specific Bars

Owns daily/reference surfaces and named app skills that are narrower than the platform teams.

| Skill | Role |
| --- | --- |
| `flight-scout` | Flight Scout app workflow. |
| `gain-tracker` | GitHub/local repo progress and daily gain stories. |
| `on-this-day` | Wikimedia same-day historical briefing and web app. |
| `on-this-day-bar` | Native daily history menu-bar app. |
| `telebar` | Telegram control center app workflow. |
| `trading-archive` | Trading/macro article archive and reading queue. |

## New Skill Gap Review

Use this checklist before auto-making a skill:

| Question | Required answer |
| --- | --- |
| Which team owns it? | Name one team above. |
| What existing skill is closest? | The new idea must be materially different from that skill. |
| What local workflow does it shorten? | It should remove repeated manual Mac work, not just describe advice. |
| What does SkillBar surface? | Include install name, icon, pack membership, and a direct default prompt. |
| What is the safety posture? | Prefer local files, explicit user-selected inputs, minimal persistence, and no hidden network calls. |

Current practical gap candidates:

| Candidate | Team | Why it may be worth building |
| --- | --- | --- |
| `mail-draft-bridge` | Workflow Handoffs And Capture | Turns selected/copied mail context into reply drafts without requiring account tokens or broad mailbox access. |
| `calendar-brief-bar` | Workflow Handoffs And Capture | Builds local meeting prep snippets from copied calendar text or user-selected exports, avoiding direct calendar permissions by default. |
| `app-permission-scout` | macOS System And Device Utilities | Audits local macOS privacy permissions and explains why a menu-bar utility cannot see a selected input. |
| `skill-idea-triage` | SkillBar And Catalog Platform | Scores proposed skill ideas against this team map before any files are created. |
