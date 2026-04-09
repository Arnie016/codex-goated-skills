#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Arnie016/codex-goated-skills.git}"
BRANCH="${BRANCH:-codex/macos-icon-bars-plugin}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/macos-icon-bars.XXXXXX")"
TRACKING_ENABLED="${MACOS_ICON_BARS_TRACKING:-1}"
COUNTER_API_BASE="${MACOS_ICON_BARS_COUNTER_API_BASE:-https://api.counterapi.dev/v1}"
COUNTER_NAMESPACE="${MACOS_ICON_BARS_COUNTER_NAMESPACE:-arnie016-codex-goated-skills}"
COUNTER_PREFIX="${MACOS_ICON_BARS_COUNTER_PREFIX:-macos-icon-bars}"
SCRIPT_FAILED=1

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

track_event() {
  local event_name="$1"
  if [[ "${TRACKING_ENABLED}" == "0" ]]; then
    return 0
  fi
  curl -fsSL --max-time 4 -o /dev/null \
    "${COUNTER_API_BASE}/${COUNTER_NAMESPACE}/${COUNTER_PREFIX}-${event_name}/up" >/dev/null 2>&1 || true
}

finish() {
  if [[ "${SCRIPT_FAILED}" -eq 0 ]]; then
    track_event "bootstrap-success"
  else
    track_event "bootstrap-failure"
  fi
}
trap finish EXIT

track_event "bootstrap-start"

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install macOS Icon Bars from GitHub." >&2
  exit 1
fi

echo "Cloning ${REPO_URL} (${BRANCH}) into a temporary workspace..."
git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${WORK_DIR}/repo" >/dev/null

echo "Running the macOS Icon Bars installer..."
"${WORK_DIR}/repo/scripts/install_macos_icon_bars.sh"
SCRIPT_FAILED=0
