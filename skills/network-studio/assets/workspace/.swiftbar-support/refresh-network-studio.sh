#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
workspace_dir="$(cd "$script_dir/.." && pwd)"
log_dir="$workspace_dir/logs"

do_scan=0
if [[ "${1:-}" == "--scan" ]]; then
  do_scan=1
fi

mkdir -p "$log_dir"

if [[ "$do_scan" -eq 1 || ! -f "$log_dir/latest-snapshot.csv" ]]; then
  bash "$workspace_dir/network-watch.sh" --once --log-dir "$log_dir" >/dev/null 2>&1 || true
fi

python3 "$script_dir/build-network-studio.py" \
  "$log_dir/latest-snapshot.csv" \
  "$log_dir/previous-snapshot.csv" \
  "$log_dir/device-history.csv" \
  "$workspace_dir/device-labels.json" \
  "$log_dir/vendor-cache.json" \
  "$log_dir/device-state.json" \
  "$log_dir/network-dashboard.html"

python3 "$script_dir/notify-network-events.py" \
  "$log_dir/device-state.json" \
  "$log_dir/alert-state.json" >/dev/null 2>&1 || true
