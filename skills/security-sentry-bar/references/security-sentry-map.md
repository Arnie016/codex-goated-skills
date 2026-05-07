# Security Sentry Bar Map

## Product Shape

- SwiftBar/XBar plugin refreshes every 60 seconds.
- First line summarizes host posture as green, yellow, or red.
- Dropdown sections show local evidence with short warning markers.
- Full scan action opens the same checks in a terminal-friendly report.

## Checks

- Network connections: `lsof -nP -iTCP -sTCP:ESTABLISHED`, remote IP, port, hostname, and non-HTTP(S) warnings.
- Listening ports: `lsof -nP -iTCP -sTCP:LISTEN`, port, process, and unexpected high-port warnings.
- LaunchAgents: plist files in `~/Library/LaunchAgents` and `/Library/LaunchAgents`, with files modified in the last 24 hours highlighted.
- Processes: top CPU and memory rows from `ps`, with executable paths under `~/.local`, `/tmp`, `/private/tmp`, or `/var/tmp` flagged.
- Recent files: Spotlight `mdfind` for files modified under `$HOME` in the last 60 minutes when available, falling back to bounded `find` while pruning `.cache`, `.git`, `node_modules`, build outputs, and common dependency folders.

## Local Configuration

- `SECURITY_SENTRY_SUSPICIOUS_CIDRS`: whitespace-separated IPv4 CIDR ranges to flag as dangerous.
- `~/.security-sentry-ranges`: optional newline-separated IPv4 CIDR watchlist.
- `SECURITY_SENTRY_RECENT_LIMIT`: max recent file rows, default 25.
- `SECURITY_SENTRY_CONNECTION_LIMIT`: max connection rows shown, default 40.
- `SECURITY_SENTRY_RECENT_MAXDEPTH`: home-directory scan depth, default 3 to keep 60-second menu refreshes responsive.
- `SECURITY_SENTRY_REVERSE_DNS`: set to `1` to allow slower reverse-DNS fallback after local cache lookup.
- `SECURITY_SENTRY_HOSTNAME_LIMIT`: max hostname lookups per refresh, default 8.

## Safety Notes

- This skill is local-first and does not fetch a remote threat feed.
- The suspicious range check is intentionally explicit so user data is not sent elsewhere.
- Findings are best-effort signals for triage, not proof of compromise.
