#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
PROJECT_NAME="VibeWidget.xcodeproj"
PROJECT_SPEC="project.yml"

usage() {
  cat <<'EOF'
Usage:
  run_vibe_bluetooth.sh [--workspace PATH] <command>

Commands:
  doctor     Check local prerequisites and project state
  generate   Regenerate the Xcode project from project.yml
  open       Generate if needed, then open the Xcode project
  build      Build the VibeWidget scheme with xcodebuild
  typecheck  Run lightweight local Swift type checks

Examples:
  bash run_vibe_bluetooth.sh doctor
  bash run_vibe_bluetooth.sh --workspace /path/to/vibe-widget open
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

guess_workspace() {
  local candidate
  for candidate in \
    "$PWD" \
    "$PWD/apps/vibe-widget" \
    "$SCRIPT_DIR/../../../apps/vibe-widget"
  do
    if [[ -f "$candidate/$PROJECT_SPEC" && -d "$candidate/VibeWidgetApp" && -d "$candidate/VibeWidgetWidget" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

check_xcode_license() {
  if DEVELOPER_DIR="$XCODE_DIR" xcodebuild -version >/dev/null 2>&1 && \
     DEVELOPER_DIR="$XCODE_DIR" xcodebuild -list -project "$WORKSPACE/$PROJECT_NAME" >/dev/null 2>&1; then
    return 0
  fi

  if DEVELOPER_DIR="$XCODE_DIR" xcodebuild -list -project "$WORKSPACE/$PROJECT_NAME" >/tmp/vibewidget-license-check.log 2>&1; then
    return 0
  fi

  if grep -qi "license" /tmp/vibewidget-license-check.log 2>/dev/null; then
    die "Xcode license not accepted. Run: sudo xcodebuild -license"
  fi

  return 1
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
  printf 'Xcode license: '
  if check_xcode_license; then
    printf 'accepted\n'
  else
    printf 'not ready\n'
  fi
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
  check_xcode_license
  (cd "$WORKSPACE" && DEVELOPER_DIR="$XCODE_DIR" xcodebuild -project "$PROJECT_NAME" -scheme VibeWidget -destination 'platform=macOS' build)
}

typecheck_project() {
  require_tools
  ensure_workspace
  local sdkroot buildcheck
  sdkroot="$(xcrun --show-sdk-path)"
  buildcheck="$WORKSPACE/.buildcheck"
  rm -rf "$buildcheck"
  mkdir -p "$buildcheck"

  (
    cd "$WORKSPACE"
    swiftc -emit-module -parse-as-library -sdk "$sdkroot" -target arm64-apple-macosx15.0 \
      -module-name VibeWidgetCore VibeWidgetCore/Sources/*.swift \
      -emit-module-path "$buildcheck/VibeWidgetCore.swiftmodule"

    swiftc -typecheck -sdk "$sdkroot" -target arm64-apple-macosx15.0 -I "$buildcheck" \
      VibeWidgetWidget/Sources/*.swift

    swiftc -typecheck -sdk "$sdkroot" -target arm64-apple-macosx15.0 -I "$buildcheck" \
      VibeWidgetApp/Sources/App/*.swift \
      VibeWidgetApp/Sources/Services/*.swift \
      VibeWidgetApp/Sources/Views/*.swift \
      VibeWidgetApp/Sources/Views/Components/*.swift
  )
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
  *)
    usage
    die "Unknown command: $COMMAND"
    ;;
esac
