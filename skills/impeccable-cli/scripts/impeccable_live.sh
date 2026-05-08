#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage: impeccable_live.sh [impeccable live args...]

Examples:
  bash skills/impeccable-cli/scripts/impeccable_live.sh
  bash skills/impeccable-cli/scripts/impeccable_live.sh --port=5199
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if command -v impeccable >/dev/null 2>&1; then
  exec impeccable live "$@"
fi

if ! command -v npx >/dev/null 2>&1; then
  echo "npx is required because the impeccable binary is not installed globally." >&2
  exit 127
fi

exec npx --yes impeccable live "$@"
