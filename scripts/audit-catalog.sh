#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

usage() {
  cat <<'EOF'
Usage:
  audit-catalog.sh [--repo-dir PATH]

Examples:
  bash scripts/audit-catalog.sh
  bash scripts/audit-catalog.sh --repo-dir /path/to/codex-goated-skills
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-dir)
      [[ $# -ge 2 ]] || {
        printf 'Error: --repo-dir requires a path\n' >&2
        exit 1
      }
      REPO_ROOT="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      printf 'Error: unknown argument: %s\n' "$1" >&2
      exit 1
      ;;
  esac
done

[[ -d "$REPO_ROOT/skills" ]] || {
  printf 'Error: no skills directory found in %s\n' "$REPO_ROOT" >&2
  exit 1
}

printf 'Running catalog audit in %s\n' "$REPO_ROOT"
printf 'Checking generated catalog index\n'
bash "$REPO_ROOT/bin/codex-goated" catalog check --repo-dir "$REPO_ROOT"
printf 'Checking skill and pack integrity\n'
bash "$REPO_ROOT/bin/codex-goated" audit --repo-dir "$REPO_ROOT"
