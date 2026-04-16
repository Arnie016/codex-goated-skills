#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
PROJECT_NAME="ClipboardStudio.xcodeproj"
PROJECT_SPEC="project.yml"
SCHEME="ClipboardStudio"
APP_BUNDLE=".build-debug/Build/Products/Debug/Context Assembly.app"
APP_EXECUTABLE="$APP_BUNDLE/Contents/MacOS/Context Assembly"
XCODE_CHECK_LOG="/tmp/clipboard-studio-xcode-check.log"

usage() {
  cat <<'EOF'
Usage:
  run_clipboard_studio.sh [--workspace PATH] <command>

Commands:
  doctor     Check local prerequisites and workspace shape
  inspect    Print the main Context Assembly files for quick orientation
  generate   Regenerate the Xcode project from project.yml
  open       Generate if needed, then open the Xcode project
  typecheck  Run a lightweight Swift source check
  build      Build the ClipboardStudio scheme with xcodebuild
  test       Run the ClipboardStudio unit tests
  run        Build and relaunch the Context Assembly menu bar app

Examples:
  bash run_clipboard_studio.sh doctor
  bash run_clipboard_studio.sh --workspace /path/to/clipboard-studio test
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required for this command."
}

guess_workspace() {
  local candidate
  for candidate in \
    "$PWD" \
    "$PWD/apps/clipboard-studio" \
    "$SCRIPT_DIR/../../../apps/clipboard-studio"
  do
    if [[ -f "$candidate/$PROJECT_SPEC" && -d "$candidate/ClipboardStudioApp" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

xcode_is_ready() {
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
  command -v xcodegen >/dev/null 2>&1 || die "xcodegen is not installed. Run: brew install xcodegen"
  command -v swiftc >/dev/null 2>&1 || die "swiftc is not available on this Mac."
}

ensure_workspace() {
  if [[ -z "$WORKSPACE" ]]; then
    WORKSPACE="$(guess_workspace || true)"
  fi
  [[ -d "$WORKSPACE" ]] || die "Workspace not found: $WORKSPACE"
  [[ -f "$WORKSPACE/$PROJECT_SPEC" ]] || die "Missing $PROJECT_SPEC in $WORKSPACE"
}

generate_project() {
  require_tools
  ensure_workspace
  (cd "$WORKSPACE" && xcodegen generate)
}

doctor() {
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
  if [[ -d "$WORKSPACE/ClipboardStudioApp/Sources" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Unit tests dir: '
  if [[ -d "$WORKSPACE/ClipboardStudioApp/Tests" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'xcrun: '
  if command -v xcrun >/dev/null 2>&1; then
    printf '%s\n' "$(xcrun --version 2>&1 | head -n 1)"
  else
    printf 'missing\n'
  fi
  printf 'xcodegen: %s\n' "$(command -v xcodegen || echo missing)"
  printf 'swiftc: %s\n' "$(command -v swiftc || echo missing)"
  printf 'Xcode readiness: '
  print_xcode_status
}

inspect_workspace() {
  ensure_workspace
  cat <<EOF
Workspace: $WORKSPACE
Main files:
- $WORKSPACE/project.yml
- $WORKSPACE/ClipboardStudioApp/Info.plist
- $WORKSPACE/ClipboardStudioApp/Sources/App/ClipboardStudioApp.swift
- $WORKSPACE/ClipboardStudioApp/Sources/App/ClipboardStudioDomain.swift
- $WORKSPACE/ClipboardStudioApp/Sources/App/ClipboardStudioModel.swift
- $WORKSPACE/ClipboardStudioApp/Sources/Services/ClipboardAutomationService.swift
- $WORKSPACE/ClipboardStudioApp/Sources/Services/CurrentContextSnapshotService.swift
- $WORKSPACE/ClipboardStudioApp/Sources/Services/ContextAssemblyExportService.swift
- $WORKSPACE/ClipboardStudioApp/Sources/Services/ContextAssemblyResearchService.swift
- $WORKSPACE/ClipboardStudioApp/Sources/Views/MenuBarView.swift
- $WORKSPACE/ClipboardStudioApp/Sources/Views/PackOverlayViews.swift
- $WORKSPACE/ClipboardStudioApp/Tests/ContextPackTests.swift
- $WORKSPACE/ClipboardStudioApp/Tests/ContextPackFormatterTests.swift
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
  require_tools
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
  require_tools
  require_tool xcrun
  ensure_workspace

  local sdkroot typecheck_dir module_cache
  local sources=()

  sdkroot="$(xcrun --sdk macosx --show-sdk-path)"
  typecheck_dir="$WORKSPACE/.build-debug/typecheck"
  module_cache="$typecheck_dir/ModuleCache"

  rm -rf "$typecheck_dir"
  mkdir -p "$module_cache"

  while IFS= read -r file; do
    sources+=("$file")
  done < <(find "$WORKSPACE/ClipboardStudioApp/Sources" -name '*.swift' | sort)

  [[ ${#sources[@]} -gt 0 ]] || die "No Swift sources found in $WORKSPACE/ClipboardStudioApp/Sources"

  (
    cd "$WORKSPACE" &&
    swiftc -typecheck \
      -sdk "$sdkroot" \
      -target arm64-apple-macosx15.0 \
      -D DEBUG \
      -module-cache-path "$module_cache" \
      -module-name ClipboardStudio \
      "${sources[@]}"
  )
}

test_project() {
  require_tools
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
  pkill -f "$WORKSPACE/$APP_EXECUTABLE" || true
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
