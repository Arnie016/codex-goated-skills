#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=""
PROJECT_NAME="CursorStudio.xcodeproj"
PROJECT_SPEC="project.yml"

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

  if [[ -f "$PWD/$PROJECT_SPEC" && -d "$PWD/CursorStudioApp" ]]; then
    printf '%s\n' "$PWD"
    return 0
  fi

  if [[ -f "$PWD/apps/vibe-widget/$PROJECT_SPEC" && -d "$PWD/apps/vibe-widget/CursorStudioApp" ]]; then
    printf '%s\n' "$PWD/apps/vibe-widget"
    return 0
  fi

  if [[ -n "${CURSOR_STUDIO_WORKSPACE:-}" && -f "${CURSOR_STUDIO_WORKSPACE}/$PROJECT_SPEC" && -d "${CURSOR_STUDIO_WORKSPACE}/CursorStudioApp" ]]; then
    printf '%s\n' "${CURSOR_STUDIO_WORKSPACE}"
    return 0
  fi

  die "Could not find a Cursor Studio workspace. Re-run with --workspace /path/to/workspace."
}

find_project_file() {
  local workspace="$1"
  local candidate

  if [[ -d "$workspace/$PROJECT_NAME" ]]; then
    printf '%s\n' "$workspace/$PROJECT_NAME"
    return 0
  fi

  for candidate in "$workspace"/*.xcodeproj; do
    [[ -d "$candidate" ]] || continue
    printf '%s\n' "$candidate"
    return 0
  done

  return 1
}

validate_workspace() {
  local workspace="$1"
  [[ -f "$workspace/$PROJECT_SPEC" ]] || die "Missing $PROJECT_SPEC in $workspace"
  [[ -d "$workspace/CursorStudioApp" ]] || die "Missing CursorStudioApp/ in $workspace"
}

print_status() {
  local label="$1"
  local value="$2"
  printf '%-14s %s\n' "$label" "$value"
}

doctor() {
  local workspace="$1"
  local found_project_file=""
  local project_file="missing"

  print_status "workspace" "$workspace"
  print_status "project.yml" "$(test -f "$workspace/$PROJECT_SPEC" && echo yes || echo no)"
  print_status "CursorStudio" "$(test -d "$workspace/CursorStudioApp" && echo yes || echo no)"
  if found_project_file="$(find_project_file "$workspace" 2>/dev/null)"; then
    project_file="$(basename "$found_project_file")"
  fi
  print_status "xcodeproj" "$project_file"
  print_status "xcodegen" "$(command -v xcodegen || echo missing)"
  print_status "xcodebuild" "$(command -v xcodebuild || echo missing)"
}

inspect() {
  local workspace="$1"
  local base="$workspace/CursorStudioApp"
  local found_project_file=""
  local project_file="missing"

  if found_project_file="$(find_project_file "$workspace" 2>/dev/null)"; then
    project_file="$found_project_file"
  fi

  print_status "workspace" "$workspace"
  print_status "project" "$project_file"
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
  local project_file

  if ! project_file="$(find_project_file "$workspace" 2>/dev/null)"; then
    generate "$workspace"
    project_file="$(find_project_file "$workspace")" || die "Missing xcodeproj in $workspace after generation."
  fi

  open "$project_file"
}

build() {
  local workspace="$1"
  local project_file

  require_tool xcodebuild
  if ! project_file="$(find_project_file "$workspace" 2>/dev/null)"; then
    generate "$workspace"
    project_file="$(find_project_file "$workspace")" || die "Missing xcodeproj in $workspace after generation."
  fi

  xcodebuild -project "$project_file" -scheme CursorStudio -destination 'platform=macOS' build
}

test_workspace() {
  local workspace="$1"
  local project_file

  require_tool xcodebuild
  if ! project_file="$(find_project_file "$workspace" 2>/dev/null)"; then
    generate "$workspace"
    project_file="$(find_project_file "$workspace")" || die "Missing xcodeproj in $workspace after generation."
  fi

  xcodebuild -project "$project_file" -scheme CursorStudio -destination 'platform=macOS' test
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
