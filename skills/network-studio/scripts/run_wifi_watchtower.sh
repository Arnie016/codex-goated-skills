#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
PROJECT_NAME="WifiWatchtower.xcodeproj"
PROJECT_SPEC="project.yml"
SCHEME="WifiWatchtower"
APP_BUNDLE=".build-debug/Build/Products/Debug/WifiWatchtower.app"
XCODE_CHECK_LOG="/tmp/wifi-watchtower-xcode-check.log"

usage() {
  cat <<'EOF'
Usage:
  run_wifi_watchtower.sh [--workspace PATH] <command>

Commands:
  doctor     Check local prerequisites and workspace shape
  inspect    Print the main WiFi Watchtower files for quick orientation
  generate   Regenerate the Xcode project from project.yml
  open       Generate if needed, then open the Xcode project
  build      Build the WifiWatchtower scheme with xcodebuild
  test       Run the WifiWatchtower unit tests
  run        Build and relaunch the WiFi Watchtower menu bar app

Examples:
  bash run_wifi_watchtower.sh doctor
  bash run_wifi_watchtower.sh --workspace /path/to/wifi-watchtower build
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

have_tool() {
  command -v "$1" >/dev/null 2>&1
}

require_tool() {
  have_tool "$1" || die "$1 is required for this command."
}

guess_workspace() {
  local candidate
  for candidate in \
    "$PWD" \
    "$PWD/apps/wifi-watchtower" \
    "$SCRIPT_DIR/../../../apps/wifi-watchtower"
  do
    if [[ -f "$candidate/$PROJECT_SPEC" && -d "$candidate/WifiWatchtowerApp" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

ensure_workspace() {
  if [[ -z "$WORKSPACE" ]]; then
    WORKSPACE="$(guess_workspace || true)"
  fi

  [[ -d "$WORKSPACE" ]] || die "Workspace not found: $WORKSPACE"
  [[ -f "$WORKSPACE/$PROJECT_SPEC" ]] || die "Missing $PROJECT_SPEC in $WORKSPACE"
}

xcode_is_ready() {
  if ! have_tool xcodebuild; then
    return 1
  fi

  if DEVELOPER_DIR="$XCODE_DIR" xcodebuild -version >/dev/null 2>&1 && \
     DEVELOPER_DIR="$XCODE_DIR" xcodebuild -list -project "$WORKSPACE/$PROJECT_NAME" >/dev/null 2>&1; then
    return 0
  fi

  if DEVELOPER_DIR="$XCODE_DIR" xcodebuild -list -project "$WORKSPACE/$PROJECT_NAME" >"$XCODE_CHECK_LOG" 2>&1; then
    return 0
  fi
  return 1
}

print_xcode_status() {
  if ! have_tool xcodebuild; then
    printf 'xcodebuild missing\n'
    return 1
  fi

  if xcode_is_ready; then
    printf 'ready\n'
    return 0
  fi

  if grep -qi "license" "$XCODE_CHECK_LOG" 2>/dev/null; then
    printf 'license not accepted (run: sudo xcodebuild -license)\n'
    return 1
  fi

  if grep -Eqi "runFirstLaunch|failed to load a required plug-in|failed to load code for plug-in" "$XCODE_CHECK_LOG" 2>/dev/null; then
    printf 'runFirstLaunch needed (run: sudo xcodebuild -runFirstLaunch)\n'
    return 1
  fi

  printf 'not ready (inspect: %s)\n' "$XCODE_CHECK_LOG"
  return 1
}

ensure_xcode_ready() {
  if xcode_is_ready; then
    return 0
  fi

  if grep -qi "license" "$XCODE_CHECK_LOG" 2>/dev/null; then
    die "Xcode license not accepted. Run: sudo xcodebuild -license"
  fi

  if grep -Eqi "runFirstLaunch|failed to load a required plug-in|failed to load code for plug-in" "$XCODE_CHECK_LOG" 2>/dev/null; then
    die "Xcode is not ready. Run: sudo xcodebuild -runFirstLaunch"
  fi

  die "xcodebuild is not ready. Inspect $XCODE_CHECK_LOG for details."
}

require_tools() {
  require_tool xcodegen
  require_tool swiftc
}

doctor() {
  require_tools
  ensure_workspace
  printf 'Workspace: %s\n' "$WORKSPACE"
  printf 'Project spec: %s\n' "$WORKSPACE/$PROJECT_SPEC"
  printf 'Xcode path: %s\n' "$XCODE_DIR"
  printf 'Project present: '
  if [[ -d "$WORKSPACE/$PROJECT_NAME" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Main source dir: '
  if [[ -d "$WORKSPACE/WifiWatchtowerApp/Sources" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Unit tests dir: '
  if [[ -d "$WORKSPACE/WifiWatchtowerApp/Tests" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Inspector service: '
  if [[ -f "$WORKSPACE/WifiWatchtowerApp/Sources/Services/WifiInspector.swift" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'xcodegen: %s\n' "$(command -v xcodegen || echo missing)"
  printf 'swiftc: %s\n' "$(command -v swiftc || echo missing)"
  printf 'xcodebuild: %s\n' "$(command -v xcodebuild || echo missing)"
  printf 'Xcode readiness: '
  print_xcode_status
}

inspect_workspace() {
  ensure_workspace
  cat <<EOF
Workspace: $WORKSPACE
Main files:
- $WORKSPACE/project.yml
- $WORKSPACE/WifiWatchtowerApp/Info.plist
- $WORKSPACE/WifiWatchtowerApp/Sources/App/WifiWatchtowerApp.swift
- $WORKSPACE/WifiWatchtowerApp/Sources/App/WatchtowerModel.swift
- $WORKSPACE/WifiWatchtowerApp/Sources/Models/NetworkSnapshot.swift
- $WORKSPACE/WifiWatchtowerApp/Sources/Services/WifiInspector.swift
- $WORKSPACE/WifiWatchtowerApp/Sources/Services/WifiTrustScorer.swift
- $WORKSPACE/WifiWatchtowerApp/Sources/Views/MenuBarView.swift
- $WORKSPACE/WifiWatchtowerApp/Sources/Views/DashboardView.swift
- $WORKSPACE/WifiWatchtowerApp/Tests/WifiTrustScorerTests.swift
EOF
}

generate_project() {
  require_tools
  ensure_workspace
  (cd "$WORKSPACE" && xcodegen generate)
}

open_project() {
  ensure_workspace
  if [[ ! -d "$WORKSPACE/$PROJECT_NAME" ]]; then
    generate_project
  fi
  open "$WORKSPACE/$PROJECT_NAME"
}

build_project() {
  require_tools
  require_tool xcodebuild
  ensure_workspace
  [[ -d "$WORKSPACE/$PROJECT_NAME" ]] || generate_project
  ensure_xcode_ready
  (
    cd "$WORKSPACE" &&
    DEVELOPER_DIR="$XCODE_DIR" xcodebuild \
      -project "$PROJECT_NAME" \
      -scheme "$SCHEME" \
      -configuration Debug \
      -derivedDataPath .build-debug \
      -destination 'platform=macOS' \
      build
  )
}

test_project() {
  require_tools
  require_tool xcodebuild
  ensure_workspace
  [[ -d "$WORKSPACE/$PROJECT_NAME" ]] || generate_project
  ensure_xcode_ready
  (
    cd "$WORKSPACE" &&
    DEVELOPER_DIR="$XCODE_DIR" xcodebuild \
      -project "$PROJECT_NAME" \
      -scheme "$SCHEME" \
      -configuration Debug \
      -derivedDataPath .build-debug \
      -destination 'platform=macOS' \
      test
  )
}

run_app() {
  build_project
  pkill -f "$WORKSPACE/$APP_BUNDLE/Contents/MacOS/WifiWatchtower" || true
  open "$WORKSPACE/$APP_BUNDLE"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)
      [[ $# -ge 2 ]] || die "--workspace requires a path"
      WORKSPACE="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      break
      ;;
  esac
done

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] || { usage; exit 1; }

case "$COMMAND" in
  doctor)
    doctor
    ;;
  inspect)
    inspect_workspace
    ;;
  generate)
    generate_project
    ;;
  open)
    open_project
    ;;
  build)
    build_project
    ;;
  test)
    test_project
    ;;
  run)
    run_app
    ;;
  *)
    usage
    die "Unknown command: $COMMAND"
    ;;
esac
