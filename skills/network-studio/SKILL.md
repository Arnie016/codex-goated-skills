---
name: network-studio
description: Install or update a macOS local-network monitor workspace, or build and troubleshoot the bundled `apps/wifi-watchtower` menu bar app. Use when Codex needs a repo-native path for LAN presence, Wi-Fi trust scanning, SwiftBar wiring, local dashboards, or compact macOS network safety surfaces on networks the user owns or administers.
---

# Network Studio

Use this skill when the user wants either:

- a self-contained Network Studio workspace that watches the local LAN, builds a browser dashboard, and optionally exposes a compact SwiftBar menu
- the bundled `apps/wifi-watchtower` macOS app that grades the current Wi-Fi connection and nearby access points from the menu bar

When this repo contains `apps/wifi-watchtower`, use that workspace first for native app requests. Use the installer lane when the user wants a portable watcher workspace, SwiftBar plugin, or a dashboard outside the repo app.

## Quick Start

1. Pick the lane first:
   - portable watcher workspace
   - native `wifi-watchtower` app
2. For the portable watcher workspace:
   - choose a workspace path, defaulting to `~/Network Studio`
   - run `python3 scripts/install_network_studio.py "<workspace-path>"`
   - if the user wants a menu bar item and uses SwiftBar, add `--swiftbar-plugins-dir ~/SwiftBarPlugins`
3. For the bundled app:
   - run `bash scripts/run_wifi_watchtower.sh doctor`
   - run `bash scripts/run_wifi_watchtower.sh inspect`
   - use `bash scripts/run_wifi_watchtower.sh generate` after changing `apps/wifi-watchtower/project.yml`
   - use `bash scripts/run_wifi_watchtower.sh build` after model, CoreWLAN, scoring, or view changes
   - use `bash scripts/run_wifi_watchtower.sh run` when you need the menu bar app relaunched from the local build
4. After a watcher install, run `bash "<workspace>/.swiftbar-support/open-network-studio.sh"` to trigger a fresh scan and open the dashboard.
5. For a continuous watcher, run `bash "<workspace>/network-watch.sh"` or add flags such as `--interval 30 --resolve`.

## Workflow

### Choose The Surface

- `network-studio-workspace`: install or refresh the portable workspace in a user-chosen folder
- `swiftbar-plugin`: wire or repair the compact SwiftBar surface that points at the installed workspace
- `wifi-watchtower-workspace`: extend or troubleshoot the bundled `apps/wifi-watchtower` macOS app
- `support-only`: explain the most reliable network-check path without building or installing anything

### Work The Bundled App First

- Read `references/project-map.md` before editing the app workspace.
- If the task changes project settings or app metadata, inspect `apps/wifi-watchtower/project.yml` and `apps/wifi-watchtower/WifiWatchtowerApp/Info.plist` first.
- Keep `WiFi Watchtower` compact and menu-bar-first.
- Prefer the local runner before typing `xcodegen` or `xcodebuild` manually.
- Run `build` after changes to:
  - CoreWLAN capture logic
  - network scoring or issue explanations
  - menu bar presentation
  - dashboard layout
  - app lifecycle or refresh timing
- If `doctor` reports that Xcode is not ready, stop and use the exact command it prints before trying `build` or `run`.

### Install Or Update The Portable Workspace

- Use `scripts/install_network_studio.py` to create or refresh the portable workspace from `assets/workspace/`.
- Preserve `device-labels.json` if it already exists.
- Preserve `logs/` contents. Do not delete history unless the user asks.
- Re-run the installer against the same workspace when the user asks to update an existing install.

### Wire SwiftBar

- Prefer pointing SwiftBar directly at `<workspace>/swiftbar` if the user is comfortable changing the plugin directory.
- If the user already uses `~/SwiftBarPlugins`, pass `--swiftbar-plugins-dir ~/SwiftBarPlugins`. The installer writes a thin wrapper there that calls the workspace plugin.

### Product Boundaries

- Use only on networks the user owns or administers.
- Explain that the portable workspace is LAN presence monitoring, not deep packet inspection.
- Explain that `WiFi Watchtower` grades the current Wi-Fi environment using local system signals. It does not prove compromise and it is not a packet sniffer.
- Recommend `brew install nmap` for more reliable portable-workspace discovery, but do not block on it.
- Note that dashboard links and label paths are generated from the installed workspace, so moving the workspace later requires a refresh or reinstall.
- Keep scans, labels, and trust explanations local by default. Do not add covert telemetry, network exfiltration, or surveillance framing.

### Native App Guidance

- Prefer `MenuBarExtra` or a compact accessory-style app surface.
- Keep the first screen action-oriented:
  - current trust grade
  - strongest reasons behind the grade
  - current gateway or DNS summary
  - nearby Wi-Fi risk summary
- Preserve clear distinction between:
  - current-network trust
  - nearby-network context
  - subjective recommendation copy
- Keep the app honest about uncertainty. A caution or avoid score should explain why in plain language.

## Resources

- `scripts/install_network_studio.py`: copies the portable workspace, preserves user state, and optionally installs a SwiftBar wrapper.
- `scripts/run_wifi_watchtower.sh`: local doctor, inspect, generate, open, build, and run helper for `apps/wifi-watchtower`.
- `references/project-map.md`: default workspace, main files, and validation notes for the bundled native app.
- `assets/workspace/`: bundled template for the watcher, dashboard builder, and SwiftBar plugin. Read or patch these files only when setup or behavior needs to change.
