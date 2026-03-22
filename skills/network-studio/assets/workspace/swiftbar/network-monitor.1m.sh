#!/usr/bin/env bash
set -euo pipefail

plugin_dir="$(cd "$(dirname "$0")" && pwd)"
workspace_dir="$(cd "$plugin_dir/.." && pwd)"
support_dir="$workspace_dir/.swiftbar-support"
log_dir="$workspace_dir/logs"
latest_file="$log_dir/latest-snapshot.csv"
state_file="$log_dir/device-state.json"
dashboard_file="$log_dir/network-dashboard.html"
refresh_script="$support_dir/refresh-network-studio.sh"
render_script="$support_dir/render-swiftbar-menu.py"
refresh_lock="$support_dir/.refresh.lock"

mkdir -p "$log_dir"

render_fallback() {
  cat <<'EOF'
| color=#e8a64f sfimage=dot.radiowaves.left.and.right
---
Network Studio
Waiting for the first build.
EOF
}

kick_background_refresh() {
  if [[ -f "$refresh_lock" ]]; then
    local existing_pid=""
    existing_pid="$(cat "$refresh_lock" 2>/dev/null || true)"
    if [[ -n "$existing_pid" ]] && kill -0 "$existing_pid" 2>/dev/null; then
      return
    fi
  fi

  (
    bash "$refresh_script" --scan >/dev/null 2>&1 || true
    rm -f "$refresh_lock"
  ) &
  echo $! > "$refresh_lock"
}

if [[ ! -f "$state_file" || ! -f "$dashboard_file" ]]; then
  bash "$refresh_script" --scan >/dev/null 2>&1 || true
elif [[ -f "$latest_file" && "$latest_file" -nt "$state_file" ]]; then
  bash "$refresh_script" >/dev/null 2>&1 || true
fi

if [[ -f "$latest_file" ]]; then
  latest_age=$(( $(date +%s) - $(stat -f %m "$latest_file") ))
  if (( latest_age > 90 )); then
    kick_background_refresh
  fi
fi

if [[ -f "$state_file" ]]; then
  python3 "$render_script" "$state_file" || render_fallback
else
  render_fallback
fi
