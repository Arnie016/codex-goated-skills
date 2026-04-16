#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
XCODE_DIR="/Applications/Xcode.app/Contents/Developer"
PROJECT_NAME="SkillBar.xcodeproj"
PROJECT_SPEC="project.yml"
SCHEME="SkillBar"
APP_BUNDLE=".build-debug/Build/Products/Debug/SkillBar.app"
XCODE_CHECK_LOG="/tmp/skillbar-xcode-check.log"

usage() {
  cat <<'EOF'
Usage:
  run_skillbar.sh [--workspace PATH] <command> [command-arg]

Commands:
  doctor                    Check local prerequisites and workspace shape
  inspect                   Print the main SkillBar files for quick orientation
  generate                  Regenerate the Xcode project from project.yml
  open                      Generate if needed, then open the Xcode project
  build                     Build the SkillBar scheme with xcodebuild
  typecheck                 Run a lightweight Swift source check
  test                      Run the SkillBar unit tests
  run                       Build and relaunch the SkillBar menu bar app
  catalog-check             Verify the generated catalog index is current
  audit                     Run the repo-wide skill and pack integrity audit
  smoke-install [skill-id]  Install one skill into a temporary destination via bin/codex-goated
  smoke-update [skill-id]    Refresh one installed skill through a temporary overwrite path

Examples:
  bash run_skillbar.sh doctor
  bash run_skillbar.sh inspect
  bash run_skillbar.sh smoke-install skillbar
  bash run_skillbar.sh typecheck
  bash run_skillbar.sh --workspace /path/to/skillbar test
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
    "$PWD/apps/skillbar" \
    "$SCRIPT_DIR/../../../apps/skillbar"
  do
    if [[ -f "$candidate/$PROJECT_SPEC" && -d "$candidate/SkillBarApp" ]]; then
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

resolve_repo_root() {
  ensure_workspace

  local current parent
  current="$WORKSPACE"
  while true; do
    if [[ -d "$current/skills" && -x "$current/bin/codex-goated" ]]; then
      printf '%s\n' "$current"
      return 0
    fi
    parent="$(dirname "$current")"
    if [[ "$parent" == "$current" ]]; then
      break
    fi
    current="$parent"
  done

  current="$PWD"
  while true; do
    if [[ -d "$current/skills" && -x "$current/bin/codex-goated" ]]; then
      printf '%s\n' "$current"
      return 0
    fi
    parent="$(dirname "$current")"
    if [[ "$parent" == "$current" ]]; then
      break
    fi
    current="$parent"
  done

  die "Could not resolve the codex-goated-skills repo root from $WORKSPACE or $PWD."
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

doctor() {
  ensure_workspace

  local repo_root cli_path
  repo_root="$(resolve_repo_root)"
  cli_path="$repo_root/bin/codex-goated"

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
  if [[ -d "$WORKSPACE/SkillBarApp/Sources" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Unit tests dir: '
  if [[ -d "$WORKSPACE/SkillBarApp/Tests" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'Repo root: %s\n' "$repo_root"
  printf 'CLI present: '
  if [[ -x "$cli_path" ]]; then
    printf 'yes\n'
  else
    printf 'no\n'
  fi
  printf 'xcodegen: %s\n' "$(command -v xcodegen || echo missing)"
  printf 'swiftc: %s\n' "$(command -v swiftc || echo missing)"
  printf 'xcrun: %s\n' "$(command -v xcrun || echo missing)"
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
- $WORKSPACE/SkillBarApp/Info.plist
- $WORKSPACE/SkillBarApp/Sources/App/SkillBarApp.swift
- $WORKSPACE/SkillBarApp/Sources/App/SkillBarModel.swift
- $WORKSPACE/SkillBarApp/Sources/Models/SkillBarModels.swift
- $WORKSPACE/SkillBarApp/Sources/Services/SkillCatalogService.swift
- $WORKSPACE/SkillBarApp/Sources/Services/SkillInstallService.swift
- $WORKSPACE/SkillBarApp/Sources/Views/MenuBarView.swift
- $WORKSPACE/SkillBarApp/Tests/SkillCatalogServiceTests.swift
- $(resolve_repo_root)/bin/codex-goated
EOF
}

generate_project() {
  require_tool xcodegen
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

  sdkroot="$(xcrun --show-sdk-path)"
  cache_dir="$(mktemp -d /tmp/skillbar-typecheck-XXXXXX)"
  trap 'rm -rf "$cache_dir"' RETURN

  while IFS= read -r file; do
    sources+=("$file")
  done < <(find "$WORKSPACE/SkillBarApp/Sources" -name '*.swift' | sort)

  [[ ${#sources[@]} -gt 0 ]] || die "No Swift sources found in $WORKSPACE/SkillBarApp/Sources"

  swiftc -typecheck \
    -sdk "$sdkroot" \
    -target arm64-apple-macosx15.0 \
    -module-name SkillBar \
    -module-cache-path "$cache_dir" \
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
  pkill -f "$WORKSPACE/$APP_BUNDLE/Contents/MacOS/SkillBar" || true
  open "$WORKSPACE/$APP_BUNDLE"
}

smoke_install() {
  ensure_workspace

  local skill_name repo_root cli_path temp_dir dest_dir installed_skill
  skill_name="${1:-skillbar}"
  repo_root="$(resolve_repo_root)"
  cli_path="$repo_root/bin/codex-goated"
  [[ -x "$cli_path" ]] || die "Missing executable CLI at $cli_path"

  temp_dir="$(mktemp -d)"
  dest_dir="$temp_dir/skills"

  if ! "$cli_path" install --repo-dir "$repo_root" --dest "$dest_dir" "$skill_name"; then
    rm -rf "$temp_dir"
    die "Smoke install command failed for $skill_name"
  fi

  installed_skill="$dest_dir/$skill_name/SKILL.md"
  if [[ ! -f "$installed_skill" ]]; then
    rm -rf "$temp_dir"
    die "Smoke install did not produce $installed_skill"
  fi

  printf 'Smoke install OK: %s\n' "$installed_skill"
  rm -rf "$temp_dir"
}

smoke_update() {
  ensure_workspace

  local skill_name repo_root cli_path temp_dir source_repo dest_dir installed_skill pre_fingerprint post_fingerprint marker
  skill_name="${1:-skillbar}"
  repo_root="$(resolve_repo_root)"
  cli_path="$repo_root/bin/codex-goated"
  [[ -x "$cli_path" ]] || die "Missing executable CLI at $cli_path"

  temp_dir="$(mktemp -d)"
  source_repo="$temp_dir/repo"
  dest_dir="$temp_dir/skills"
  marker="skillbar-smoke-update"

  mkdir -p "$source_repo/bin" "$source_repo/skills" "$dest_dir"
  cp "$cli_path" "$source_repo/bin/codex-goated"
  cp -R "$repo_root/skills/$skill_name" "$source_repo/skills/$skill_name"

  if ! "$source_repo/bin/codex-goated" install --repo-dir "$source_repo" --dest "$dest_dir" "$skill_name"; then
    rm -rf "$temp_dir"
    die "Smoke update setup failed for $skill_name"
  fi

  installed_skill="$dest_dir/$skill_name/SKILL.md"
  [[ -f "$installed_skill" ]] || {
    rm -rf "$temp_dir"
    die "Smoke update did not produce $installed_skill"
  }

  pre_fingerprint="$(cksum < "$installed_skill")"
  printf '\n<!-- %s -->\n' "$marker" >> "$source_repo/skills/$skill_name/SKILL.md"

  if ! "$source_repo/bin/codex-goated" update --repo-dir "$source_repo" --dest "$dest_dir" "$skill_name"; then
    rm -rf "$temp_dir"
    die "Smoke update command failed for $skill_name"
  fi

  post_fingerprint="$(cksum < "$installed_skill")"
  if [[ "$pre_fingerprint" == "$post_fingerprint" ]]; then
    rm -rf "$temp_dir"
    die "Smoke update did not refresh $installed_skill"
  fi

  if ! grep -Fq "<!-- $marker -->" "$installed_skill"; then
    rm -rf "$temp_dir"
    die "Smoke update did not copy the updated marker into $installed_skill"
  fi

  printf 'Smoke update OK: %s\n' "$installed_skill"
  rm -rf "$temp_dir"
}

catalog_check() {
  ensure_workspace

  local repo_root cli_path
  repo_root="$(resolve_repo_root)"
  cli_path="$repo_root/bin/codex-goated"
  [[ -x "$cli_path" ]] || die "Missing executable CLI at $cli_path"

  if ! "$cli_path" catalog check --repo-dir "$repo_root"; then
    die "Catalog check failed for $repo_root"
  fi
}

audit_repo() {
  ensure_workspace

  local repo_root cli_path
  repo_root="$(resolve_repo_root)"
  cli_path="$repo_root/bin/codex-goated"
  [[ -x "$cli_path" ]] || die "Missing executable CLI at $cli_path"

  if ! "$cli_path" audit --repo-dir "$repo_root"; then
    die "Repo audit failed for $repo_root"
  fi
}

COMMAND=""
COMMAND_ARG=""

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
      if [[ $# -gt 0 ]]; then
        COMMAND_ARG="$1"
        shift
      fi
      break
      ;;
  esac
done

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
  smoke-install)
    smoke_install "$COMMAND_ARG"
    ;;
  smoke-update)
    smoke_update "$COMMAND_ARG"
    ;;
  catalog-check)
    catalog_check
    ;;
  audit)
    audit_repo
    ;;
  *)
    usage
    die "Unknown command: $COMMAND"
    ;;
esac
