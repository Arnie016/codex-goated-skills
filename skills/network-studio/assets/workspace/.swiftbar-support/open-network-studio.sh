#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
workspace_dir="$(cd "$script_dir/.." && pwd)"

bash "$script_dir/refresh-network-studio.sh" --scan >/dev/null 2>&1 || true
if command -v open >/dev/null 2>&1; then
  if open -a Safari "$workspace_dir/logs/network-dashboard.html" >/dev/null 2>&1; then
    exit 0
  fi

  if open "$workspace_dir/logs/network-dashboard.html" >/dev/null 2>&1; then
    exit 0
  fi
fi

printf 'Dashboard: %s\n' "$workspace_dir/logs/network-dashboard.html"
