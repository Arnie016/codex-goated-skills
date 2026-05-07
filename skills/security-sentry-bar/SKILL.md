---
name: security-sentry-bar
description: Build, install, or refine a local-first macOS security monitor for SwiftBar/XBar that summarizes network connections, listening ports, LaunchAgents, unusual processes, and recent file changes from the menu bar without hidden network feeds.
---

# Security Sentry Bar

Use this skill when the user wants a compact macOS menu-bar security posture check, especially a SwiftBar or XBar plugin that runs local checks every minute.

Default product shape: a SwiftBar-compatible Bash plugin with a green/yellow/red menu-bar status, expandable security sections, a manual full-scan action, and a SwiftUI prototype for a native menu-bar version.

## Quick Start

1. Run `bash scripts/run_security_sentry_bar.sh doctor` to check local tools and the SwiftBar plugin destination.
2. Install the plugin with `bash scripts/run_security_sentry_bar.sh install`.
3. Use `bash scripts/run_security_sentry_bar.sh preview` to render one menu snapshot in the terminal.
4. Use `bash scripts/run_security_sentry_bar.sh full-scan` when the user wants the complete report outside the menu.
5. Keep findings local, explicit, and best-effort. Do not add hidden threat feeds, background persistence, or remote telemetry.

## Workflow

### SwiftBar Plugin

- The plugin lives at `scripts/security-sentry-bar.1m.sh`.
- Install copies it to `~/SwiftBarPlugins/security-sentry-bar.1m.sh` by default.
- The first menu line uses SwiftBar color and SF Symbol metadata for safe, warning, and danger states.
- Dropdown sections cover network connections, listening ports, LaunchAgents, running processes, and recent file changes.
- `Run Full Scan` opens the same script in full-scan mode through SwiftBar.

### Security Boundaries

- Treat this as a local triage surface, not an antivirus engine or packet sniffer.
- Do not require root. If a command has partial visibility without privileges, explain the limitation in the menu.
- Do not upload process names, file paths, IPs, or hostnames.
- Suspicious IP ranges are local and explicit: users may add CIDR ranges via `SECURITY_SENTRY_SUSPICIOUS_CIDRS` or `~/.security-sentry-ranges`.
- Keep recent-file scanning bounded with exclusions and result limits.

### Native Swift Prototype

- Use `prototype/SkillMenuBarApp.swift`, `SkillMenuBarView.swift`, `SkillDetailView.swift`, and `SkillTheme.swift` as the native SwiftUI shape if the user later wants a compiled menu-bar app.
- Preserve the same state model: connection count, warning count, danger count, scan age, and section summaries.
- Keep actions explicit. A native version should launch scans on demand or on a visible refresh cadence, not through hidden persistence.

## Resources

- `scripts/security-sentry-bar.1m.sh`: SwiftBar/XBar plugin.
- `scripts/run_security_sentry_bar.sh`: doctor, install, preview, full-scan, and syntax-test helper.
- `references/security-sentry-map.md`: product boundaries, checks, and local configuration.
- `assets/`: small and large SVG icons for SkillBar/catalog surfaces.
- `prototype/`: SwiftUI menu-bar starter for a native implementation.
