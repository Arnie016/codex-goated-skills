#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
PROJECT_NAME="MinecraftSkinBar.xcodeproj"
PROJECT_SPEC="project.yml"
SCHEME="MinecraftSkinBar"
APP_BUNDLE=".build-debug/Build/Products/Debug/MinecraftSkinBar.app"
XCODE_CHECK_LOG="/tmp/minecraft-skinbar-xcode-check.log"
LAUNCHER_JSON="$HOME/Library/Application Support/minecraft/launcher_custom_skins.json"
SKILL_SCRIPT="$SCRIPT_DIR/minecraft_skin_studio.py"

usage() {
  cat <<'EOF'
Usage:
  run_minecraft_skinbar.sh [--workspace PATH] <command>

Commands:
  doctor     Check local prerequisites and workspace shape
  inspect    Print the main Minecraft Skin Bar files for quick orientation
  generate   Regenerate the Xcode project from project.yml
  open       Generate if needed, then open the Xcode project
  build      Build the MinecraftSkinBar scheme with xcodebuild
  run        Build and relaunch the Minecraft Skin Bar app

Examples:
  bash run_minecraft_skinbar.sh doctor
  bash run_minecraft_skinbar.sh --workspace /path/to/minecraft-skinbar build
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
    "$PWD/apps/minecraft-skinbar" \
    "$SCRIPT_DIR/../../../apps/minecraft-skinbar"
  do
    if [[ -f "$candidate/$PROJECT_SPEC" && -d "$candidate/MinecraftSkinBarApp" ]]; then
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

resolve_uv() {
  local candidate
  for candidate in \
    "${UV_BIN:-}" \
    "/opt/homebrew/bin/uv" \
    "/usr/local/bin/uv"
  do
    [[ -n "$candidate" ]] || continue
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  if command -v uv >/dev/null 2>&1; then
    command -v uv
    return 0
  fi

  return 1
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
  local uv_path=""
  require_tools
  ensure_workspace
  if uv_path="$(resolve_uv 2>/dev/null)"; then
    :
  else
    uv_path=""
  fi

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
  if [[ -d "$WORKSPACE/MinecraftSkinBarApp/Sources" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Skill script: '
  if [[ -f "$SKILL_SCRIPT" ]]; then
    printf '%s\n' "$SKILL_SCRIPT"
  else
    printf 'missing (%s)\n' "$SKILL_SCRIPT"
  fi
  printf 'uv: '
  if [[ -n "$uv_path" ]]; then
    printf '%s\n' "$uv_path"
  else
    printf 'not found (Generate/Import in the app will fail until uv is installed)\n'
  fi
  printf 'Launcher JSON: '
  if [[ -f "$LAUNCHER_JSON" ]]; then
    printf 'present (%s)\n' "$LAUNCHER_JSON"
  else
    printf 'not created yet (%s)\n' "$LAUNCHER_JSON"
  fi
  printf 'OPENAI_API_KEY env: '
  if [[ -n "${OPENAI_API_KEY:-}" ]]; then
    printf 'set\n'
  else
    printf 'not set (the app can still use Keychain)\n'
  fi
  printf 'Xcode readiness: '
  print_xcode_status
}

inspect_workspace() {
  ensure_workspace
  cat <<EOF
Workspace: $WORKSPACE
Main files:
- $WORKSPACE/project.yml
- $WORKSPACE/MinecraftSkinBarApp/Info.plist
- $WORKSPACE/MinecraftSkinBarApp/Sources/App/MinecraftSkinBarApp.swift
- $WORKSPACE/MinecraftSkinBarApp/Sources/App/SkinBarModel.swift
- $WORKSPACE/MinecraftSkinBarApp/Sources/Services/SkinStudioCLI.swift
- $WORKSPACE/MinecraftSkinBarApp/Sources/Services/KeychainStore.swift
- $WORKSPACE/MinecraftSkinBarApp/Sources/Views/MenuBarView.swift
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

run_app() {
  build_project
  pkill -f "$WORKSPACE/$APP_BUNDLE/Contents/MacOS/MinecraftSkinBar" || true
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
  run)
    run_app
    ;;
  *)
    usage
    die "Unknown command: $COMMAND"
    ;;
esac
