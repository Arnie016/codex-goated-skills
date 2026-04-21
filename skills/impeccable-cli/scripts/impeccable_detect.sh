#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: impeccable_detect.sh [impeccable detect args...]

Examples:
  bash skills/impeccable-cli/scripts/impeccable_detect.sh src/
  bash skills/impeccable-cli/scripts/impeccable_detect.sh --json src/
  bash skills/impeccable-cli/scripts/impeccable_detect.sh --fast app/components
  bash skills/impeccable-cli/scripts/impeccable_detect.sh https://example.com
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -eq 0 ]]; then
  usage >&2
  exit 64
fi

if command -v impeccable >/dev/null 2>&1; then
  exec impeccable detect "$@"
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required because the impeccable binary is not installed globally." >&2
  exit 127
fi

exec npx --yes impeccable detect "$@"
