#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
PROJECT_NAME="FlightScout.xcodeproj"
PROJECT_SPEC="project.yml"
SCHEME="FlightScout"
APP_BUNDLE=".build-debug/Build/Products/Debug/FlightScout.app"
XCODE_CHECK_LOG="/tmp/flight-scout-xcode-check.log"

usage() {
  cat <<'EOF'
Usage:
  run_flight_scout.sh [--workspace PATH] <command>

Commands:
  doctor     Check local prerequisites and workspace shape
  inspect    Print the main Flight Scout files for quick orientation
  generate   Regenerate the Xcode project from project.yml
  open       Generate if needed, then open the Xcode project
  typecheck  Run a lightweight Swift source check
  build      Build the FlightScout scheme with xcodebuild
  test       Run the FlightScout test bundle
  run        Build and relaunch the Flight Scout menu bar app

Examples:
  bash run_flight_scout.sh doctor
  bash run_flight_scout.sh --workspace /path/to/flight-scout build
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

tool_version() {
  local tool="$1"
  case "$tool" in
    xcodebuild)
      xcodebuild -version 2>&1 | head -n 1
      ;;
    xcodegen|swiftc)
      "$tool" --version 2>&1 | head -n 1
      ;;
    *)
      "$tool" --version 2>&1 | head -n 1
      ;;
  esac
}

guess_workspace() {
  local candidate
  for candidate in \
    "$PWD" \
    "$PWD/apps/flight-scout" \
    "$SCRIPT_DIR/../../../apps/flight-scout"
  do
    if [[ -f "$candidate/$PROJECT_SPEC" && -d "$candidate/FlightScoutApp" && -d "$candidate/VibeWidgetCore" ]]; then
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

print_tool() {
  local tool="$1"
  if have_tool "$tool"; then
    printf '%s\n' "$(tool_version "$tool")"
  else
    printf 'missing\n'
  fi
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
  printf 'App sources: '
  if [[ -d "$WORKSPACE/FlightScoutApp/Sources" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Shared framework: '
  if [[ -d "$WORKSPACE/VibeWidgetCore/Sources" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Tests: '
  if [[ -d "$WORKSPACE/FlightScoutApp/Tests" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'xcrun: %s\n' "$(print_tool xcrun)"
  printf 'xcodegen: %s\n' "$(print_tool xcodegen)"
  printf 'swiftc: %s\n' "$(print_tool swiftc)"
  printf 'xcodebuild: %s\n' "$(print_tool xcodebuild)"
  printf 'Xcode readiness: '
  print_xcode_status
}

inspect_workspace() {
  ensure_workspace
  cat <<EOF
Workspace: $WORKSPACE
Main files:
- $WORKSPACE/project.yml
- $WORKSPACE/FlightScoutApp/Info.plist
- $WORKSPACE/FlightScoutApp/Sources/App/FlightScoutApp.swift
- $WORKSPACE/FlightScoutApp/Sources/App/FlightScoutStatusBarController.swift
- $WORKSPACE/FlightScoutApp/Sources/App/FlightScoutAppModel.swift
- $WORKSPACE/FlightScoutApp/Sources/Services/FlightScoutEngine.swift
- $WORKSPACE/FlightScoutApp/Sources/Services/FlightScoutRankingService.swift
- $WORKSPACE/FlightScoutApp/Sources/Services/FlightPriceSearchService.swift
- $WORKSPACE/FlightScoutApp/Sources/Views/FlightScoutMenuBarView.swift
- $WORKSPACE/FlightScoutApp/Sources/Views/FlightScoutBoardView.swift
- $WORKSPACE/FlightScoutApp/Tests/FlightScoutTests.swift
- $WORKSPACE/VibeWidgetCore/Sources
EOF
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

  local sdkroot typecheck_dir module_cache
  local core_sources=()
  local app_sources=()

  sdkroot="$(xcrun --sdk macosx --show-sdk-path)"
  typecheck_dir="$(mktemp -d /tmp/flight-scout-typecheck-XXXXXX)"
  module_cache="$typecheck_dir/ModuleCache"
  trap 'rm -rf "$typecheck_dir"' RETURN
  mkdir -p "$module_cache"

  while IFS= read -r file; do
    core_sources+=("$file")
  done < <(find "$WORKSPACE/VibeWidgetCore/Sources" -name '*.swift' | sort)

  while IFS= read -r file; do
    app_sources+=("$file")
  done < <(find "$WORKSPACE/FlightScoutApp/Sources" -name '*.swift' | sort)

  [[ ${#core_sources[@]} -gt 0 ]] || die "No Swift sources found in $WORKSPACE/VibeWidgetCore/Sources"
  [[ ${#app_sources[@]} -gt 0 ]] || die "No Swift sources found in $WORKSPACE/FlightScoutApp/Sources"

  (
    cd "$WORKSPACE"

    swiftc -emit-module -parse-as-library \
      -sdk "$sdkroot" \
      -target arm64-apple-macosx15.0 \
      -D DEBUG \
      -module-cache-path "$module_cache" \
      -module-name VibeWidgetCore \
      "${core_sources[@]}" \
      -emit-module-path "$typecheck_dir/VibeWidgetCore.swiftmodule"

    swiftc -typecheck \
      -sdk "$sdkroot" \
      -target arm64-apple-macosx15.0 \
      -D DEBUG \
      -module-cache-path "$module_cache" \
      -I "$typecheck_dir" \
      -module-name FlightScout \
      "${app_sources[@]}"
  )
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
  pkill -f "$WORKSPACE/$APP_BUNDLE/Contents/MacOS/$SCHEME" || true
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
  typecheck)
    typecheck_project
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
