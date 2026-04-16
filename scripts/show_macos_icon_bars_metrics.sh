#!/usr/bin/env bash
set -euo pipefail

COUNTER_API_BASE="${MACOS_ICON_BARS_COUNTER_API_BASE:-https://api.counterapi.dev/v1}"
COUNTER_NAMESPACE="${MACOS_ICON_BARS_COUNTER_NAMESPACE:-arnie016-codex-goated-skills}"
COUNTER_PREFIX="${MACOS_ICON_BARS_COUNTER_PREFIX:-macos-icon-bars}"

fetch_counter() {
  local name="$1"
  local response
  if ! response="$(curl -fsSL --max-time 6 "${COUNTER_API_BASE}/${COUNTER_NAMESPACE}/${COUNTER_PREFIX}-${name}" 2>/dev/null)"; then
    echo "0"
    return 0
  fi
  python3 - "${response}" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])

print(payload.get("count", payload.get("data", payload.get("value", 0))))
PY
}

fetch_series() {
  local name="$1"
  local response
  if ! response="$(curl -fsSL --max-time 6 "${COUNTER_API_BASE}/${COUNTER_NAMESPACE}/${COUNTER_PREFIX}-${name}/list?group_by=day&order_by=desc" 2>/dev/null)"; then
    return 0
  fi
  python3 - "${response}" <<'PY'
import json
import sys

payload = json.loads(sys.argv[1])

rows = payload if isinstance(payload, list) else payload.get("data", [])
for item in rows[:7]:
    print(f"{item.get('Date', 'Unknown')}: {item.get('Value', item.get('count', 0))}")
PY
}

echo "macOS Icon Bars metrics"
echo
printf '%-28s %s\n' "One-command starts" "$(fetch_counter "bootstrap-start")"
printf '%-28s %s\n' "One-command successes" "$(fetch_counter "bootstrap-success")"
printf '%-28s %s\n' "Installer starts" "$(fetch_counter "install-start")"
printf '%-28s %s\n' "Installer successes" "$(fetch_counter "install-success")"
printf '%-28s %s\n' "Approx unique installs" "$(fetch_counter "install-unique-success")"
printf '%-28s %s\n' "Installer failures" "$(fetch_counter "install-failure")"

series="$(fetch_series "install-unique-success" || true)"
if [[ -n "${series}" ]]; then
  echo
  echo "Recent unique installs by day"
  echo "${series}"
fi
