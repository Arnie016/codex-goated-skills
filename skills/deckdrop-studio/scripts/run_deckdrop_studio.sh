#!/usr/bin/env bash
set -euo pipefail

WORKSPACE=""

usage() {
  cat <<'EOF'
Usage:
  run_deckdrop_studio.sh [--workspace PATH] <doctor|inspect|generate|open|build|test>

Examples:
  bash scripts/run_deckdrop_studio.sh doctor
  bash scripts/run_deckdrop_studio.sh --workspace /path/to/workspace inspect
  bash scripts/run_deckdrop_studio.sh --workspace /path/to/workspace test
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

detect_workspace() {
  if [[ -n "${WORKSPACE:-}" ]]; then
    printf '%s\n' "$WORKSPACE"
    return 0
  fi

  if [[ -f "$PWD/project.yml" && -d "$PWD/DeckDropApp" ]]; then
    printf '%s\n' "$PWD"
    return 0
  fi

  if [[ -f "$PWD/apps/vibe-widget/project.yml" && -d "$PWD/apps/vibe-widget/DeckDropApp" ]]; then
    printf '%s\n' "$PWD/apps/vibe-widget"
    return 0
  fi

  if [[ -n "${DECKDROP_WORKSPACE:-}" && -f "${DECKDROP_WORKSPACE}/project.yml" && -d "${DECKDROP_WORKSPACE}/DeckDropApp" ]]; then
    printf '%s\n' "${DECKDROP_WORKSPACE}"
    return 0
  fi

  die "Could not find a DeckDrop workspace. Re-run with --workspace /path/to/workspace."
}

validate_workspace() {
  local workspace="$1"
  [[ -f "$workspace/project.yml" ]] || die "Missing project.yml in $workspace"
  [[ -d "$workspace/DeckDropApp" ]] || die "Missing DeckDropApp/ in $workspace"
}

print_status() {
  local label="$1"
  local value="$2"
  printf '%-14s %s\n' "$label" "$value"
}

doctor() {
  local workspace="$1"
  local project="$workspace/VibeWidget.xcodeproj"

  print_status "workspace" "$workspace"
  print_status "project.yml" "$(test -f "$workspace/project.yml" && echo yes || echo no)"
  print_status "DeckDropApp" "$(test -d "$workspace/DeckDropApp" && echo yes || echo no)"
  print_status "xcodeproj" "$(test -d "$project" && echo yes || echo no)"
  print_status "python3" "$(command -v python3 || echo missing)"
  print_status "node" "$(command -v node || echo missing)"
  print_status "xcodegen" "$(command -v xcodegen || echo missing)"
  print_status "xcodebuild" "$(command -v xcodebuild || echo missing)"
}

inspect() {
  local workspace="$1"
  local base="$workspace/DeckDropApp"

  print_status "workspace" "$workspace"
  print_status "model" "$base/Sources/App/DeckDropAppModel.swift"
  print_status "services" "$base/Sources/Services"
  print_status "views" "$base/Sources/Views"
  print_status "scripts" "$base/Resources/scripts"
  print_status "writer" "$base/DeckWriter/package.json"
  print_status "tests" "$base/Tests/DeckDropTests.swift"
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
  local project="$workspace/VibeWidget.xcodeproj"
  [[ -d "$project" ]] || die "Missing $project. Run generate first."
  open "$project"
}

build() {
  local workspace="$1"
  local project="$workspace/VibeWidget.xcodeproj"
  [[ -d "$project" ]] || die "Missing $project. Run generate first."
  require_tool xcodebuild
  xcodebuild -project "$project" -scheme DeckDrop -destination 'platform=macOS' build
}

test_workspace() {
  local workspace="$1"
  local project="$workspace/VibeWidget.xcodeproj"
  [[ -d "$project" ]] || die "Missing $project. Run generate first."
  require_tool xcodebuild
  xcodebuild -project "$project" -scheme DeckDrop -destination 'platform=macOS' test
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
  doctor)
    doctor "$RESOLVED_WORKSPACE"
    ;;
  inspect)
    inspect "$RESOLVED_WORKSPACE"
    ;;
  generate)
    generate "$RESOLVED_WORKSPACE"
    ;;
  open)
    open_project "$RESOLVED_WORKSPACE"
    ;;
  build)
    build "$RESOLVED_WORKSPACE"
    ;;
  test)
    test_workspace "$RESOLVED_WORKSPACE"
    ;;
  *)
    die "Unknown command: $COMMAND"
    ;;
esac
