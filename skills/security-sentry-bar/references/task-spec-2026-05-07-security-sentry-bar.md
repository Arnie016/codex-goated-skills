# Task Spec: Security Sentry Bar

## Goal

Add a practical local-first macOS Icon Bars skill that installs a SwiftBar/XBar security monitor for host posture checks.

## Scope

- Create `skills/security-sentry-bar`.
- Include a SwiftBar-compatible Bash plugin refreshing every 60 seconds.
- Include a runner helper for doctor, install, preview, full-scan, and shell-test flows.
- Include small/large SVG icons and SwiftUI prototype files for a future native menu-bar app.
- Add manifest/catalog metadata and pack coverage.
- Keep checks local and explicit, with no hidden threat feed or telemetry.

## Product Fit

- Primary team: macOS System And Device Utilities / `macos-utility-builders`.
- Closest existing skill: `network-studio`.
- Difference: `network-studio` monitors LAN presence and dashboard output; `security-sentry-bar` monitors host-level signals across network connections, listening ports, LaunchAgents, processes, and recent files.

## Guardrails

- Do not require root access.
- Do not persist scan results unless the user explicitly adds that later.
- Do not claim malware detection; this is triage and posture monitoring.
- Do not add remote suspicious-IP feeds. Use only explicit local CIDR configuration.
