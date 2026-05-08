#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
TARGET_SCRIPT="$REPO_ROOT/skills/skillbar/scripts/run_skillbar.sh"

if [[ ! -f "$TARGET_SCRIPT" ]]; then
  printf 'Error: missing packaged SkillBar runner at %s\n' "$TARGET_SCRIPT" >&2
  exit 1
fi

exec bash "$TARGET_SCRIPT" "$@"
