# codex-goated-skills

OpenSkills for Codex: a growing collection of reusable OpenAI Codex skills and mini apps.

`network-studio` is the first thing vibe coded in this repo.

This repository is meant to stay simple:

- `skills/` contains installable Codex skills
- `apps/` contains larger shareable app projects over time
- each skill is self-contained and can be installed directly from GitHub

## Install A Skill

Inside Codex, run:

```text
$skill-installer install https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio
```

Then restart Codex.

## First Vibe-Coded Skill

### `network-studio`

This was the first build in `codex-goated-skills`: a macOS LAN presence monitor packaged as a reusable Codex skill.

What it sets up:

- a local `Network Studio` workspace
- a SwiftBar wrapper that points to the installed workspace
- an initial refresh that generates `network-dashboard.html`
- a `latest-snapshot.csv` device snapshot
- stronger discovery via `nmap` when available

What it is:

- local network presence monitoring
- watchlists for trusted and unknown devices
- a browser dashboard plus a menu bar view

What it is not:

- deep packet inspection
- full traffic analysis for every device on the network

## Apps In Progress

### `vibe-widget`

The next build in the repo is `VibeWidget`, a native macOS SwiftUI app with a WidgetKit extension for voice-first vibe control.

Included in the app codebase:

- `VibeWidget.xcodeproj` for the Xcode project
- `VibeWidgetApp` for onboarding, dashboard, AI panel, and native service scaffolding
- `VibeWidgetWidget` for the widget and App Intents
- `VibeWidgetCore` for shared models, app-group snapshot storage, keychain access, and fallback command parsing

Current verification state:

- `xcodegen generate` succeeded
- source-level type-check passes succeeded locally
- full `xcodebuild` is still blocked until Xcode's license is accepted with `sudo xcodebuild -license`

Path in this repo:

[`apps/vibe-widget`](/Users/arnav/Desktop/codex-goated-skills/apps/vibe-widget)

## Available Skills

### `network-studio`

Install or update a macOS local network monitor with:

- a SwiftBar menu bar plugin
- a browser dashboard
- device watchlists
- trusted and unknown device sections
- change feeds for joins, returns, and missing devices

Direct install URL:

```text
https://github.com/Arnie016/codex-goated-skills/tree/main/skills/network-studio
```

Example prompt:

```text
Use $network-studio to install Network Studio in ~/Network Studio and wire SwiftBar at ~/SwiftBarPlugins.
```

### `vibe-bluetooth`

Work on the VibeWidget macOS app and widget through a reusable development skill.

- repo-aware doctor, generate, open, build, and typecheck commands
- project map for app, widget, and shared core targets
- defaults to `apps/vibe-widget` in this repo when present

Direct install URL:

```text
https://github.com/Arnie016/codex-goated-skills/tree/main/skills/vibe-bluetooth
```

Example prompt:

```text
Use $vibe-bluetooth to work on apps/vibe-widget, regenerate the project if needed, and run typecheck.
```

## Manual Install

If someone wants to install manually without `$skill-installer`:

```bash
mkdir -p ~/.codex/skills
git clone https://github.com/Arnie016/codex-goated-skills.git
cp -R codex-goated-skills/skills/network-studio ~/.codex/skills/network-studio
```

Then restart Codex.

## Topics And Discovery

Recommended GitHub repo description:

`Open-source skills and mini apps for OpenAI Codex`

Recommended GitHub topics:

- `codex`
- `openai-codex`
- `codex-skills`
- `agent-skills`
- `ai-agents`
- `developer-tools`
- `automation`
- `swiftbar`
- `macos`

## License

This repository is licensed under MIT. Individual skills may also include their own `LICENSE.txt`.
