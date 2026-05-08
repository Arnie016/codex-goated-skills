#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
PROJECT_NAME="TradingArchiveBar.xcodeproj"
PROJECT_SPEC="project.yml"
SCHEME="TradingArchiveBar"
APP_BUNDLE=".build-debug/Build/Products/Debug/TradingArchiveBar.app"
HELPER_SCRIPT="$SCRIPT_DIR/fetch_trading_feeds.py"
XCODE_CHECK_LOG="/tmp/trading-archive-xcode-check.log"

usage() {
  cat <<'EOF'
Usage:
  run_trading_archive.sh [--workspace PATH] <command>

Commands:
  doctor     Check local prerequisites and workspace shape
  inspect    Print the main Trading Archive files for quick orientation
  fetch      Run the deterministic feed helper and emit a snapshot
  generate   Regenerate the Xcode project from project.yml
  open       Generate if needed, then open the Xcode project
  typecheck  Run a lightweight Swift source check
  build      Build the TradingArchiveBar scheme with xcodebuild
  test       Run the TradingArchiveBar unit tests
  run        Build and relaunch the Trading Archive Bar menu bar app

Examples:
  bash run_trading_archive.sh doctor
  bash run_trading_archive.sh fetch --feed-url https://example.com/feed.xml --limit 20
  bash run_trading_archive.sh --workspace /path/to/trading-archive-bar test
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

have_tool() {
  command -v "$1" >/dev/null 2>&1
}

tool_version() {
  local tool="$1"
  case "$tool" in
    xcodebuild)
      xcodebuild -version 2>&1 | head -n 1
      ;;
    *)
      "$tool" --version 2>&1 | head -n 1
      ;;
  esac
}

print_tool_status() {
  local tool="$1"
  if have_tool "$tool"; then
    printf '%s\n' "$(tool_version "$tool")"
  else
    printf 'missing\n'
  fi
}

require_tool() {
  have_tool "$1" || die "$1 is required for this command."
}

guess_workspace() {
  local candidate
  for candidate in \
    "$PWD" \
    "$PWD/apps/trading-archive-bar" \
    "$SCRIPT_DIR/../../../apps/trading-archive-bar"
  do
    if [[ -f "$candidate/$PROJECT_SPEC" && -d "$candidate/TradingArchiveBarApp" ]]; then
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
    printf 'missing\n'
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

generate_project() {
  require_tool xcodegen
  ensure_workspace
  (cd "$WORKSPACE" && xcodegen generate)
}

doctor() {
  ensure_workspace
  printf 'Workspace: %s\n' "$WORKSPACE"
  printf 'Project spec: %s\n' "$WORKSPACE/$PROJECT_SPEC"
  printf 'Project present: '
  if [[ -d "$WORKSPACE/$PROJECT_NAME" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Main source dir: '
  if [[ -d "$WORKSPACE/TradingArchiveBarApp/Sources" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Unit tests dir: '
  if [[ -d "$WORKSPACE/TradingArchiveBarApp/Tests" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Feed helper: '
  if [[ -f "$HELPER_SCRIPT" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'python3: %s\n' "$(print_tool_status python3)"
  printf 'xcodegen: %s\n' "$(print_tool_status xcodegen)"
  printf 'swiftc: %s\n' "$(print_tool_status swiftc)"
  printf 'xcodebuild: %s\n' "$(print_tool_status xcodebuild)"
  printf 'Xcode readiness: '
  print_xcode_status
}

inspect_workspace() {
  ensure_workspace
  cat <<EOF
Workspace: $WORKSPACE
Main files:
- $WORKSPACE/project.yml
- $WORKSPACE/TradingArchiveBarApp/Info.plist
- $WORKSPACE/TradingArchiveBarApp/Sources/App/TradingArchiveBarApp.swift
- $WORKSPACE/TradingArchiveBarApp/Sources/App/TradingArchiveBarAppModel.swift
- $WORKSPACE/TradingArchiveBarApp/Sources/App/TradingArchiveBarModels.swift
- $WORKSPACE/TradingArchiveBarApp/Sources/Services/TradingArchiveFeedService.swift
- $WORKSPACE/TradingArchiveBarApp/Sources/Services/TradingArchiveStore.swift
- $WORKSPACE/TradingArchiveBarApp/Sources/Views/TradingArchiveBarMenuBarView.swift
- $WORKSPACE/TradingArchiveBarApp/Sources/Views/TradingArchiveBarSettingsView.swift
- $WORKSPACE/TradingArchiveBarApp/Sources/Views/TradingArchiveBarTheme.swift
- $WORKSPACE/TradingArchiveBarApp/Tests/TradingArchiveBarTests.swift
- $SCRIPT_DIR/../references/product-spec.md
- $SCRIPT_DIR/fetch_trading_feeds.py
- $SCRIPT_DIR/../references/project-map.md
EOF
}

fetch_snapshot() {
  require_tool python3
  python3 "$HELPER_SCRIPT" "$@"
}

open_project() {
  ensure_workspace
  if [[ ! -d "$WORKSPACE/$PROJECT_NAME" ]]; then
    generate_project
  fi
  open "$WORKSPACE/$PROJECT_NAME"
}

build_project() {
  require_tool xcodegen
  require_tool swiftc
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

typecheck_project() {
  require_tool swiftc
  require_tool xcrun
  ensure_workspace

  local sdkroot cache_dir
  local sources=()

  sdkroot="$(xcrun --sdk macosx --show-sdk-path)"
  cache_dir="$(mktemp -d /tmp/trading-archive-typecheck-XXXXXX)"
  trap 'rm -rf "$cache_dir"' RETURN

  while IFS= read -r file; do
    sources+=("$file")
  done < <(find "$WORKSPACE/TradingArchiveBarApp/Sources" -name '*.swift' | sort)

  [[ ${#sources[@]} -gt 0 ]] || die "No Swift sources found in $WORKSPACE/TradingArchiveBarApp/Sources"

  swiftc -typecheck \
    -sdk "$sdkroot" \
    -target arm64-apple-macosx15.0 \
    -D DEBUG \
    -module-cache-path "$cache_dir" \
    -module-name TradingArchiveBar \
    "${sources[@]}"
}

test_project() {
  require_tool xcodegen
  require_tool swiftc
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
  pkill -f "$WORKSPACE/$APP_BUNDLE/Contents/MacOS/TradingArchiveBar" || true
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
shift || true

case "$COMMAND" in
  doctor)
    doctor
    ;;
  inspect)
    inspect_workspace
    ;;
  fetch)
    fetch_snapshot "$@"
    ;;
  generate)
    generate_project
    ;;
  open)
    open_project
    ;;
  typecheck)
    typecheck_project
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
