# codex-goated-skills

Open-source Codex skills and apps.

[![License: MIT](https://img.shields.io/badge/license-MIT-111827?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/LICENSE)
[![Install All](https://img.shields.io/badge/install-all_skills-0f172a?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/scripts/install-all-skills.sh)
[![Install By Name](https://img.shields.io/badge/install-by_name-1d4ed8?style=flat-square)](https://github.com/Arnie016/codex-goated-skills/blob/main/scripts/install-skill.sh)

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
codex-goated install find-my-phone-studio
codex-goated install cursor-studio
codex-goated install folder-studio
codex-goated install dark-pdf-studio
codex-goated install --all
codex-goated update vibe-bluetooth
```

Raw script fallback:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Arnie016/codex-goated-skills/main/scripts/install-skill.sh) network-studio
```

Then restart Codex.

## Skills vs Apps

- `skills/` are installable Codex skill packages
- `apps/` are standalone project codebases you can open, build, and run

## Skills

| Skill | What it does | Install name |
| --- | --- | --- |
| <img src="skills/repo-launch/assets/repo-launch-small.svg" width="26" alt="Repo Launch" /><br/>[`repo-launch`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/repo-launch) | Audits and upgrades a rough project into a clean public repo | `repo-launch` |
| <img src="skills/website-drop/assets/website-drop-small.svg" width="26" alt="Website Drop" /><br/>[`website-drop`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/website-drop) | Audits a web app, picks a host, and gets it live fast | `website-drop` |
| <img src="skills/brand-kit/assets/brand-kit-small.svg" width="26" alt="Brand Kit" /><br/>[`brand-kit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/brand-kit) | Builds a reusable logo, color, and launch metadata system | `brand-kit` |
| <img src="skills/content-pack/assets/content-pack-small.svg" width="26" alt="Content Pack" /><br/>[`content-pack`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/content-pack) | Turns one project into paste-ready launch and README copy | `content-pack` |
| <img src="skills/clipboard-studio/assets/clipboard-studio-small.svg" width="26" alt="Clipboard Studio" /><br/>[`clipboard-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/clipboard-studio) | Shapes a macOS copy-and-paste power tool with history, pinned snippets, and transforms | `clipboard-studio` |
| <img src="skills/find-my-phone-studio/assets/find-my-phone-studio-small.svg" width="26" alt="Find My Phone Studio" /><br/>[`find-my-phone-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/find-my-phone-studio) | Builds a realistic Mac phone-finder utility with locate, ring, call, QR pairing, and provider-aware handoff flows | `find-my-phone-studio` |
| <img src="skills/minecraft-essentials/assets/minecraft-essentials-small.svg" width="26" alt="Minecraft Essentials" /><br/>[`minecraft-essentials`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-essentials) | Runs, upgrades, and troubleshoots Minecraft Java servers | `minecraft-essentials` |
| <img src="skills/minecraft-skin-studio/assets/minecraft-skin-studio-small.svg" width="26" alt="Minecraft Skin Studio" /><br/>[`minecraft-skin-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-skin-studio) | Drafts, previews, and registers Minecraft Java skins from prompts or PNGs | `minecraft-skin-studio` |
| <img src="skills/network-studio/assets/network-studio-small.svg" width="26" alt="Network Studio" /><br/>[`network-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio) | macOS LAN monitor with SwiftBar and a dashboard | `network-studio` |
| <img src="skills/deckdrop-studio/assets/deckdrop-studio-small.svg" width="26" alt="Deckdrop Studio" /><br/>[`deckdrop-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/deckdrop-studio) | Builds and refines editable slide deck workflows for mixed-source inputs | `deckdrop-studio` |
| <img src="skills/cursor-studio/assets/cursor-studio-small.svg" width="26" alt="Cursor Studio" /><br/>[`cursor-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/cursor-studio) | Builds and refines a macOS cursor-pack planner with preset, slot, and export workflows | `cursor-studio` |
| <img src="skills/folder-studio/assets/folder-studio-small.svg" width="26" alt="Folder Studio" /><br/>[`folder-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/folder-studio) | Builds and refines a macOS folder-skin app with context-aware Finder icon workflows | `folder-studio` |
| <img src="skills/dark-pdf-studio/assets/dark-pdf-studio-small.svg" width="26" alt="Dark PDF Studio" /><br/>[`dark-pdf-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/dark-pdf-studio) | Converts PDFs, docs, and images into dark-background reading PDFs with a compact export flow | `dark-pdf-studio` |
| <img src="skills/telebar/assets/telebar-small.svg" width="26" alt="TeleBar" /><br/>[`telebar`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/telebar) | Builds and runs the TeleBar Telegram + AI menu bar app | `telebar` |
| <img src="skills/vibe-bluetooth/assets/vibe-bluetooth-small.svg" width="26" alt="VibeBluetooth" /><br/>[`vibe-bluetooth`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/vibe-bluetooth) | Dev skill for the VibeWidget macOS app and widget | `vibe-bluetooth` |
| <img src="skills/workspace-doctor/assets/workspace-doctor-small.svg" width="26" alt="Workspace Doctor" /><br/>[`workspace-doctor`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/workspace-doctor) | Finds the real local setup blocker and next fix fast | `workspace-doctor` |

## Apps

| App | What it is | Path |
| --- | --- | --- |
| `minecraft-skinbar` | macOS menu bar app for generating, importing, and opening Minecraft skins | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/minecraft-skinbar) |
| `clipboard-studio` | macOS menu bar clipboard context stacker for capture, history, and quick paste back into your editor | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/clipboard-studio) |
| `phone-spotter` | macOS menu bar phone recovery utility with QR pairing, saved clues, and Apple or Google provider handoff | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/phone-spotter) |
| `flight-scout` | macOS menu bar flight watcher with live fare signals, booking deeplinks, and travel risk scoring | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/flight-scout) |
| `telebar` | macOS Telegram control center for inbox, AI writing, and setup flows | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/telebar) |
| `wifi-watchtower` | macOS menu bar Wi-Fi trust monitor with nearby scan grading | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/wifi-watchtower) |
| `vibe-widget` | macOS SwiftUI app + widget for voice-first vibe control | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/vibe-widget) |
