---
name: network-studio
description: Install or update a macOS local-network device monitor with a SwiftBar menu and browser dashboard. Use when Codex needs to set up, refresh, relocate, or troubleshoot a LAN presence monitor for a network the user owns or administers, especially when they want device watchlists, unknown-device surfacing, change feeds, or a menu bar network status view.
---

# Network Studio

Install or refresh a self-contained macOS workspace that watches the local LAN, builds a browser dashboard, and optionally exposes a compact SwiftBar menu.

## Quick Start

1. Choose a workspace path. Default to `~/Network Studio` unless the user asks for another location.
2. Run `python3 scripts/install_network_studio.py "<workspace-path>"`.
3. If the user wants a menu bar item and uses SwiftBar, add `--swiftbar-plugins-dir ~/SwiftBarPlugins`.
4. After install, run `bash "<workspace>/.swiftbar-support/open-network-studio.sh"` to trigger a fresh scan and open the dashboard.
5. For a continuous watcher, run `bash "<workspace>/network-watch.sh"` or add flags such as `--interval 30 --resolve`.

## Workflow

### Install Or Update

- Use `scripts/install_network_studio.py` to create or refresh the workspace from `assets/workspace/`.
- Preserve `device-labels.json` if it already exists.
- Preserve `logs/` contents. Do not delete history unless the user asks.
- Re-run the installer against the same workspace when the user asks to update an existing install.

### Wire SwiftBar

- Prefer pointing SwiftBar directly at `<workspace>/swiftbar` if the user is comfortable changing the plugin directory.
- If the user already uses `~/SwiftBarPlugins`, pass `--swiftbar-plugins-dir ~/SwiftBarPlugins`. The installer writes a thin wrapper there that calls the workspace plugin.

### Explain Scope

- Use only on networks the user owns or administers.
- Explain that this is LAN presence monitoring, not deep packet inspection.
- Recommend `brew install nmap` for more reliable discovery, but do not block on it.
- Note that dashboard links and label paths are generated from the installed workspace, so moving the workspace later requires a refresh or reinstall.

## Resources

- `scripts/install_network_studio.py`: copy the portable workspace, preserve user state, and optionally install a SwiftBar wrapper.
- `assets/workspace/`: bundled template for the watcher, dashboard builder, and SwiftBar plugin. Read or patch these files only when setup or behavior needs to change.
