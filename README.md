# codex-goated-skills

Community Codex skills and apps for macOS, automation, deployment, design, networking, PDFs, slides, developer workflows, and personality-led audience strategy.

Install by name, browse by use case, or pull the full pack when you want a broader toolbox.

`SkillBar` is now the primary local manager for the pack: a professional macOS menu bar app that reads this repo, shows what is already installed under `~/.codex/skills`, and enables curated preset bundles from the top bar.

[![License: MIT](https://img.shields.io/badge/license-MIT-111827?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/LICENSE)
[![Install All](https://img.shields.io/badge/install-all_skills-0f172a?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/scripts/install-all-skills.sh)
[![Install By Name](https://img.shields.io/badge/install-by_name-1d4ed8?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/scripts/install-skill.sh)
[![Install Fandom Pack](https://img.shields.io/badge/install-fandom_pack-e76f51?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/scripts/install-fandom-pack.sh)
[![Browse Packs](https://img.shields.io/badge/browse-packs-0ea5e9?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/collections/README.md)
[![Catalog Audit](https://img.shields.io/badge/catalog-audit-10b981?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/README.md)

## Install

Install the CLI once:

```bash
curl -fsSL https://raw.githubusercontent.com/Arnie016/codex-goated-skills/main/scripts/install-cli.sh | sh
```

Then use:

```bash
codex-goated list
codex-goated install network-studio
codex-goated install minecraft-essentials
codex-goated install deckdrop-studio
codex-goated install clipboard-studio
codex-goated install skillbar
codex-goated install find-my-phone-studio
codex-goated install cursor-studio
codex-goated install folder-studio
codex-goated install dark-pdf-studio
codex-goated install fan-canon-miner comment-pulse-board iconography-lab
codex-goated search minecraft
codex-goated audit
codex-goated pack list
codex-goated pack show fandom-skill-pack
codex-goated pack show creator-and-fandom-stack
codex-goated pack install fandom-skill-pack
codex-goated pack install launch-and-distribution
codex-goated install --all
codex-goated update vibe-bluetooth
```

Raw script fallback:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Arnie016/codex-goated-skills/main/scripts/install-skill.sh) network-studio
```

Install a pack:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Arnie016/codex-goated-skills/main/scripts/install-pack.sh) creator-and-fandom-stack
```

Then restart Codex.

## Skills vs Apps

- `skills/` are installable Codex skill packages
- `apps/` are standalone project codebases you can open, build, and run

## Collections and Catalog

- Browse all use-case packs in [`collections/README.md`](https://github.com/Arnie016/codex-goated-skills/blob/main/collections/README.md)
- Browse the full audited skill catalog in [`catalog/README.md`](https://github.com/Arnie016/codex-goated-skills/blob/main/catalog/README.md)
- Use `codex-goated search <query>` when you know the problem but not the skill name yet
- Use `codex-goated audit` to validate the skill packages and pack coverage locally

## Start Here

- Fix the blocker first with `workspace-doctor`
- Ship a project with `repo-launch`, `website-drop`, or `content-pack`
- Build a utility with `network-studio`, `find-my-phone-studio`, or `clipboard-studio`
- Build a personality-led audience strategy stack with the [`Fandom Skill Pack`](https://github.com/Arnie016/codex-goated-skills/blob/main/collections/fandom-skill-pack.md)
- Browse all download packs in [`collections/README.md`](https://github.com/Arnie016/codex-goated-skills/blob/main/collections/README.md)
- Manage the whole pack from the top bar with `skillbar`
- Create polished outputs with `dark-pdf-studio` and `deckdrop-studio`

## Skills

Browse by use case:
[Launch and Distribution](#launch-and-distribution) ·
[Productivity and Workflow](#productivity-and-workflow) ·
[Audience and Fandom Strategy](#audience-and-fandom-strategy) ·
[macOS Utility Builders](#macos-utility-builders) ·
[App-Specific Skills](#app-specific-skills) ·
[Games and Minecraft](#games-and-minecraft)

### Launch and Distribution

| Skill | What it does | Install name |
| --- | --- | --- |
| <img src="skills/repo-launch/assets/repo-launch-small.svg" width="26" alt="Repo Launch" /><br/>[`repo-launch`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/repo-launch) | Audits and upgrades a rough project into a clean public repo | `repo-launch` |
| <img src="skills/website-drop/assets/website-drop-small.svg" width="26" alt="Website Drop" /><br/>[`website-drop`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/website-drop) | Audits a web app, picks a host, and gets it live fast | `website-drop` |
| <img src="skills/brand-kit/assets/brand-kit-small.svg" width="26" alt="Brand Kit" /><br/>[`brand-kit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/brand-kit) | Builds a reusable logo, color, and launch metadata system | `brand-kit` |
| <img src="skills/content-pack/assets/content-pack-small.svg" width="26" alt="Content Pack" /><br/>[`content-pack`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/content-pack) | Turns one project into paste-ready launch and README copy | `content-pack` |

### Productivity and Workflow

| Skill | What it does | Install name |
| --- | --- | --- |
| <img src="skills/workspace-doctor/assets/workspace-doctor-small.svg" width="26" alt="Workspace Doctor" /><br/>[`workspace-doctor`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/workspace-doctor) | Finds the real local setup blocker and next fix fast | `workspace-doctor` |
| <img src="skills/skillbar/assets/skillbar-small.svg" width="26" alt="SkillBar" /><br/>[`skillbar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/skillbar) | Builds and refines SkillBar, the macOS top-bar manager for the goated skill catalog, installed state, and preset bundles | `skillbar` |
| <img src="skills/clipboard-studio/assets/clipboard-studio-small.svg" width="26" alt="Context Assembly" /><br/>[`clipboard-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/clipboard-studio) | Shapes Context Assembly on macOS so code, logs, pages, and selections become one structured prompt with resumable state instead of Cmd+C, switch, Cmd+V loops | `clipboard-studio` |
| <img src="skills/network-studio/assets/network-studio-small.svg" width="26" alt="Network Studio" /><br/>[`network-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio) | macOS LAN monitor with SwiftBar and a dashboard | `network-studio` |
| <img src="skills/dark-pdf-studio/assets/dark-pdf-studio-small.svg" width="26" alt="Dark PDF Studio" /><br/>[`dark-pdf-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/dark-pdf-studio) | Converts PDFs, docs, and images into dark-background reading PDFs with a compact export flow | `dark-pdf-studio` |
| <img src="skills/deckdrop-studio/assets/deckdrop-studio-small.svg" width="26" alt="Deckdrop Studio" /><br/>[`deckdrop-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/deckdrop-studio) | Builds and refines editable slide deck workflows for mixed-source inputs | `deckdrop-studio` |

### Audience and Fandom Strategy

Collection:
[`Fandom Skill Pack`](https://github.com/Arnie016/codex-goated-skills/blob/main/collections/fandom-skill-pack.md)

| Skill | What it does | Install name |
| --- | --- | --- |
| <img src="skills/fan-canon-miner/assets/icon-small.svg" width="26" alt="Fan Canon Miner" /><br/>[`fan-canon-miner`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/fan-canon-miner) | Mines comments, interviews, captions, and fan chatter into a usable canon map | `fan-canon-miner` |
| <img src="skills/comment-pulse-board/assets/icon-small.svg" width="26" alt="Comment Pulse Board" /><br/>[`comment-pulse-board`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/comment-pulse-board) | Clusters obsession points, recurring questions, sentiment shifts, and backlash signals | `comment-pulse-board` |
| <img src="skills/clip-to-canon-finder/assets/icon-small.svg" width="26" alt="Clip To Canon Finder" /><br/>[`clip-to-canon-finder`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/clip-to-canon-finder) | Scores clips, transcripts, and reactions to find moments that deserve repeat canon | `clip-to-canon-finder` |
| <img src="skills/iconography-lab/assets/icon-small.svg" width="26" alt="Iconography Lab" /><br/>[`iconography-lab`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/iconography-lab) | Defines the recognizable visual and verbal codes of a personality-led brand | `iconography-lab` |
| <img src="skills/ritual-engine/assets/icon-small.svg" width="26" alt="Ritual Engine" /><br/>[`ritual-engine`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/ritual-engine) | Designs repeatable fan rituals, loops, naming systems, and recurring formats | `ritual-engine` |
| <img src="skills/parasocial-studio/assets/icon-small.svg" width="26" alt="Parasocial Studio" /><br/>[`parasocial-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/parasocial-studio) | Shapes safe closeness mechanics and recurring relationship touchpoints | `parasocial-studio` |
| <img src="skills/lore-drop-planner/assets/icon-small.svg" width="26" alt="Lore Drop Planner" /><br/>[`lore-drop-planner`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/lore-drop-planner) | Plans episodic reveals, callbacks, teasers, and payoff arcs | `lore-drop-planner` |
| <img src="skills/inner-circle-director/assets/icon-small.svg" width="26" alt="Inner Circle Director" /><br/>[`inner-circle-director`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/inner-circle-director) | Structures tiered access, VIP mechanics, and premium community experiences | `inner-circle-director` |
| <img src="skills/myth-merch-studio/assets/icon-small.svg" width="26" alt="Myth Merch Studio" /><br/>[`myth-merch-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/myth-merch-studio) | Turns symbols, phrases, and fandom lore into merch and collectible concepts | `myth-merch-studio` |
| <img src="skills/reputation-heatmap/assets/icon-small.svg" width="26" alt="Reputation Heatmap" /><br/>[`reputation-heatmap`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/reputation-heatmap) | Separates healthy mystique from rumor, overreach, parasocial risk, or brand harm | `reputation-heatmap` |

### macOS Utility Builders

| Skill | What it does | Install name |
| --- | --- | --- |
| <img src="skills/find-my-phone-studio/assets/find-my-phone-studio-small.svg" width="26" alt="Find My Phone Studio" /><br/>[`find-my-phone-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/find-my-phone-studio) | Builds a realistic Mac phone-finder utility with locate, ring, call, QR pairing, and provider-aware handoff flows | `find-my-phone-studio` |
| <img src="skills/cursor-studio/assets/cursor-studio-small.svg" width="26" alt="Cursor Studio" /><br/>[`cursor-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/cursor-studio) | Builds and refines a macOS cursor-pack planner with preset, slot, and export workflows | `cursor-studio` |
| <img src="skills/folder-studio/assets/folder-studio-small.svg" width="26" alt="Folder Studio" /><br/>[`folder-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/folder-studio) | Builds and refines a macOS folder-skin app with context-aware Finder icon workflows | `folder-studio` |

### App-Specific Skills

| Skill | What it does | Install name |
| --- | --- | --- |
| <img src="skills/telebar/assets/telebar-small.svg" width="26" alt="TeleBar" /><br/>[`telebar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/telebar) | Builds and runs the TeleBar Telegram + AI menu bar app | `telebar` |
| <img src="skills/vibe-bluetooth/assets/vibe-bluetooth-small.svg" width="26" alt="VibeBluetooth" /><br/>[`vibe-bluetooth`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/vibe-bluetooth) | Dev skill for the VibeWidget macOS app and widget | `vibe-bluetooth` |

### Games and Minecraft

| Skill | What it does | Install name |
| --- | --- | --- |
| <img src="skills/minecraft-essentials/assets/minecraft-essentials-small.svg" width="26" alt="Minecraft Essentials" /><br/>[`minecraft-essentials`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-essentials) | Runs, upgrades, and troubleshoots Minecraft Java servers | `minecraft-essentials` |
| <img src="skills/minecraft-skin-studio/assets/minecraft-skin-studio-small.svg" width="26" alt="Minecraft Skin Studio" /><br/>[`minecraft-skin-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-skin-studio) | Drafts, previews, and registers Minecraft Java skins from prompts or PNGs | `minecraft-skin-studio` |

## Apps

| App | What it is | Path |
| --- | --- | --- |
| `minecraft-skinbar` | macOS menu bar app for generating, importing, and opening Minecraft skins | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/minecraft-skinbar) |
| `clipboard-studio` | Context Assembly, a macOS menu bar app that turns code, logs, pages, and saved app state into one structured prompt, Apple Note, or Markdown export instead of manual copy-paste switching | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/clipboard-studio) |
| `phone-spotter` | macOS menu bar phone recovery utility with QR pairing, saved clues, and Apple or Google provider handoff | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/phone-spotter) |
| `flight-scout` | macOS menu bar flight watcher with live fare signals, booking deeplinks, and travel risk scoring | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/flight-scout) |
| `skillbar` | macOS menu bar manager for browsing the goated skill catalog, installed local skills, and preset bundles | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/skillbar) |
| `telebar` | macOS Telegram control center for inbox, AI writing, and setup flows | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/telebar) |
| `wifi-watchtower` | macOS menu bar Wi-Fi trust monitor with nearby scan grading | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/wifi-watchtower) |
| `vibe-widget` | macOS SwiftUI app + widget for voice-first vibe control | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/vibe-widget) |
