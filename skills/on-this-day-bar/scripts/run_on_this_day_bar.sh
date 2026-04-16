#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DELEGATE="$SCRIPT_DIR/../../on-this-day/scripts/run_on_this_day_bar.sh"

if [[ ! -x "$DELEGATE" ]]; then
  printf 'Error: shared runner not found: %s\n' "$DELEGATE" >&2
  exit 1
fi

exec "$DELEGATE" "$@"
