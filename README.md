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
| <img src="skills/website-drop/assets/website-drop-small.svg" width="26" alt="Website Drop" /><br/>[`website-drop`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/website-drop) | Audits a web project and gets it ready for live deploy | `website-drop` |
| <img src="skills/brand-kit/assets/brand-kit-small.svg" width="26" alt="Brand Kit" /><br/>[`brand-kit`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/brand-kit) | Builds a reusable logo, color, and launch metadata system | `brand-kit` |
| <img src="skills/content-pack/assets/content-pack-small.svg" width="26" alt="Content Pack" /><br/>[`content-pack`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/content-pack) | Turns one project into paste-ready launch and README copy | `content-pack` |
| <img src="skills/minecraft-essentials/assets/minecraft-essentials-small.svg" width="26" alt="Minecraft Essentials" /><br/>[`minecraft-essentials`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-essentials) | Runs, upgrades, and troubleshoots Minecraft Java servers | `minecraft-essentials` |
| <img src="skills/minecraft-skin-studio/assets/minecraft-skin-studio-small.svg" width="26" alt="Minecraft Skin Studio" /><br/>[`minecraft-skin-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/minecraft-skin-studio) | Drafts, previews, and registers Minecraft Java skins from prompts or PNGs | `minecraft-skin-studio` |
| <img src="skills/network-studio/assets/network-studio-small.svg" width="26" alt="Network Studio" /><br/>[`network-studio`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio) | macOS LAN monitor with SwiftBar and a dashboard | `network-studio` |
| <img src="skills/vibe-bluetooth/assets/vibe-bluetooth-small.svg" width="26" alt="VibeBluetooth" /><br/>[`vibe-bluetooth`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/vibe-bluetooth) | Dev skill for the VibeWidget macOS app and widget | `vibe-bluetooth` |
| <img src="skills/workspace-doctor/assets/workspace-doctor-small.svg" width="26" alt="Workspace Doctor" /><br/>[`workspace-doctor`](https://github.com/Arnie016/codex-goated-skills/tree/main/skills/workspace-doctor) | Finds the real local setup blocker and next fix fast | `workspace-doctor` |

## Apps

| App | What it is | Path |
| --- | --- | --- |
| `minecraft-skinbar` | macOS menu bar app for generating, importing, and opening Minecraft skins | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/minecraft-skinbar) |
| `wifi-watchtower` | macOS menu bar Wi-Fi trust monitor with nearby scan grading | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/wifi-watchtower) |
| `vibe-widget` | macOS SwiftUI app + widget for voice-first vibe control | [link](https://github.com/Arnie016/codex-goated-skills/tree/main/apps/vibe-widget) |
