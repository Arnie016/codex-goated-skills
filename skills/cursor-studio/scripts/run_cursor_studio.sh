#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=""

usage() {
  cat <<'EOF'
Usage:
  run_cursor_studio.sh [--workspace PATH] <doctor|inspect|generate|open|build|test>
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_tool() {
  command -v "$1" >/dev/null 2>&1 || die "$1 is required for this command."
}

detect_workspace() {
  if [[ -n "${WORKSPACE:-}" ]]; then
    printf '%s\n' "$WORKSPACE"
    return 0
  fi

  if [[ -f "$PWD/project.yml" && -d "$PWD/CursorStudioApp" ]]; then
    printf '%s\n' "$PWD"
    return 0
  fi

  if [[ -f "$PWD/apps/vibe-widget/project.yml" && -d "$PWD/apps/vibe-widget/CursorStudioApp" ]]; then
    printf '%s\n' "$PWD/apps/vibe-widget"
    return 0
  fi

  if [[ -n "${CURSOR_STUDIO_WORKSPACE:-}" && -f "${CURSOR_STUDIO_WORKSPACE}/project.yml" && -d "${CURSOR_STUDIO_WORKSPACE}/CursorStudioApp" ]]; then
    printf '%s\n' "${CURSOR_STUDIO_WORKSPACE}"
    return 0
  fi

  die "Could not find a Cursor Studio workspace. Re-run with --workspace /path/to/workspace."
}

validate_workspace() {
  local workspace="$1"
  [[ -f "$workspace/project.yml" ]] || die "Missing project.yml in $workspace"
  [[ -d "$workspace/CursorStudioApp" ]] || die "Missing CursorStudioApp/ in $workspace"
}

print_status() {
  local label="$1"
  local value="$2"
  printf '%-14s %s\n' "$label" "$value"
}

doctor() {
  local workspace="$1"
  print_status "workspace" "$workspace"
  print_status "project.yml" "$(test -f "$workspace/project.yml" && echo yes || echo no)"
  print_status "CursorStudio" "$(test -d "$workspace/CursorStudioApp" && echo yes || echo no)"
  print_status "xcodeproj" "$(test -d "$workspace/VibeWidget.xcodeproj" && echo yes || echo no)"
  print_status "xcodegen" "$(command -v xcodegen || echo missing)"
  print_status "xcodebuild" "$(command -v xcodebuild || echo missing)"
}

inspect() {
  local workspace="$1"
  local base="$workspace/CursorStudioApp"
  print_status "workspace" "$workspace"
  print_status "model" "$base/Sources/App/CursorStudioAppModel.swift"
  print_status "statusbar" "$base/Sources/App/CursorStudioStatusBarController.swift"
  print_status "views" "$base/Sources/Views"
  print_status "tests" "$base/Tests/CursorStudioTests.swift"
}

generate() {
  local workspace="$1"
  require_tool xcodegen
  (
    cd "$workspace"
    xcodegen generate
  )
}

open_project() {
  local workspace="$1"
  open "$workspace/VibeWidget.xcodeproj"
}

build() {
  local workspace="$1"
  require_tool xcodebuild
  xcodebuild -project "$workspace/VibeWidget.xcodeproj" -scheme CursorStudio -destination 'platform=macOS' build
}

test_workspace() {
  local workspace="$1"
  require_tool xcodebuild
  xcodebuild -project "$workspace/VibeWidget.xcodeproj" -scheme CursorStudio -destination 'platform=macOS' test
}

COMMAND=""

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
      COMMAND="$1"
      shift
      ;;
  esac
done

[[ -n "$COMMAND" ]] || die "Pass a command. Use --help for usage."

RESOLVED_WORKSPACE="$(detect_workspace)"
validate_workspace "$RESOLVED_WORKSPACE"

case "$COMMAND" in
  doctor) doctor "$RESOLVED_WORKSPACE" ;;
  inspect) inspect "$RESOLVED_WORKSPACE" ;;
  generate) generate "$RESOLVED_WORKSPACE" ;;
  open) open_project "$RESOLVED_WORKSPACE" ;;
  build) build "$RESOLVED_WORKSPACE" ;;
  test) test_workspace "$RESOLVED_WORKSPACE" ;;
  *) die "Unknown command: $COMMAND" ;;
esac
