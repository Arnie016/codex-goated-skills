#!/usr/bin/env bash
set -euo pipefail

REPO_URL="${REPO_URL:-https://github.com/Arnie016/codex-goated-skills.git}"
BRANCH="${BRANCH:-codex/macos-icon-bars-plugin}"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/macos-icon-bars.XXXXXX")"

cleanup() {
  rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to install macOS Icon Bars from GitHub." >&2
  exit 1
fi

echo "Cloning ${REPO_URL} (${BRANCH}) into a temporary workspace..."
git clone --depth 1 --branch "${BRANCH}" "${REPO_URL}" "${WORK_DIR}/repo" >/dev/null

echo "Running the macOS Icon Bars installer..."
"${WORK_DIR}/repo/scripts/install_macos_icon_bars.sh"
