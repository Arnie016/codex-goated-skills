# Network Studio Workspace Map

Default workspace: install into a user-chosen folder, usually `~/Network Studio`.

## Target

- Portable Network Studio workspace with a local watcher loop, dashboard output, and optional SwiftBar wrapper

## Main Files

- `scripts/install_network_studio.py`: installs or refreshes the workspace template and optional SwiftBar wrapper
- `assets/workspace/network-watch.sh`: continuous LAN watcher and CSV logger
- `assets/workspace/swiftbar/network-monitor.1m.sh`: SwiftBar entrypoint that renders the menu bar snapshot
- `assets/workspace/.swiftbar-support/open-network-studio.sh`: dashboard opener used after install
- `assets/workspace/.swiftbar-support/refresh-network-studio.sh`: refresh helper that rebuilds the dashboard and menu output
- `assets/workspace/.swiftbar-support/render-dashboard.py`: dashboard renderer for the installed workspace
- `assets/workspace/.swiftbar-support/render-swiftbar-menu.py`: SwiftBar menu renderer for the installed workspace
- `assets/workspace/.swiftbar-support/manual-rescan.sh`: helper for one-off refreshes
- `assets/workspace/device-labels.json`: optional persistent labels preserved on update

## Run And Install Notes

- Use the installer first:
  `python3 scripts/install_network_studio.py <workspace>`
- Add `--swiftbar-plugins-dir ~/SwiftBarPlugins` when you want a thin SwiftBar wrapper installed for the workspace.
- After install, run:
  `bash "<workspace>/.swiftbar-support/open-network-studio.sh"`
- For a continuous watcher, run:
  `bash "<workspace>/network-watch.sh"`
- `network-watch.sh --once` performs a single scan and exits.
- `network-watch.sh --interval 30 --resolve` enables a faster loop with hostname lookups.

## Constraints

- Keep monitoring local-first and limited to networks the user owns or administers.
- Treat the workspace as LAN presence monitoring, not deep packet inspection.
- Recommend `brew install nmap` for more reliable discovery, but do not block on it.
- Preserve `device-labels.json` and `logs/` contents on refresh so user state survives updates.
