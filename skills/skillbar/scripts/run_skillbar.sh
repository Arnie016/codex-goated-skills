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

summarize_xcodebuild_failure() {
  local log_path
  log_path="$1"

  if grep -Fqi "Sandbox restriction" "$log_path" || \
     grep -Fqi "testmanagerd.control was invalidated" "$log_path"; then
    if grep -Fqi "Testing started" "$log_path" || grep -Fqi "Test session results" "$log_path"; then
      printf 'SkillBar built, but the macOS sandbox blocked the test runner connection to testmanagerd.control'
      return 0
    fi

    printf 'macOS sandbox blocked the test runner connection to testmanagerd.control'
    return 0
  fi

  if grep -Fqi "CoreSimulator is out of date" "$log_path"; then
    printf 'CoreSimulator is out of date for the installed Xcode build'
    return 0
  fi

  if grep -Fqi "Failed to establish communication with the test runner" "$log_path"; then
    printf 'xcodebuild could not establish communication with the macOS test runner'
    return 0
  fi

  return 1
}

test_environment_guidance() {
  case "$1" in
    "Codex seatbelt sandbox blocks the macOS test runner in this session")
      printf 'Run `bash scripts/run_skillbar.sh typecheck` plus the smoke checks here; use `SKILLBAR_FORCE_TEST=1` only if you intentionally want the raw sandboxed xcodebuild failure.'
      return 0
      ;;
    "CoreSimulator is out of date for the installed Xcode build")
      printf 'Open Xcode once to finish platform/component updates when convenient; this warning affects simulator tooling, but the macOS SkillBar test run may still proceed.'
      return 0
      ;;
    *"testmanagerd.control"*)
      printf 'Run `bash scripts/run_skillbar.sh typecheck` plus the smoke checks here; full tests need a less restricted macOS session.'
      return 0
      ;;
    "xcodebuild could not establish communication with the macOS test runner")
      printf 'Retry after reopening Xcode or restarting the test session, then rerun `bash scripts/run_skillbar.sh test`.'
      return 0
      ;;
  esac

  return 1
}

test_environment_allows_macos_tests() {
  case "$1" in
    "CoreSimulator is out of date for the installed Xcode build")
      return 0
      ;;
  esac

  return 1
}

print_test_environment_status() {
  local status guidance
  status="$1"
  printf '%s\n' "$status"
  if guidance="$(test_environment_guidance "$status")"; then
    printf '  Next step: %s\n' "$guidance"
  fi
}

format_test_environment_error() {
  local status guidance
  status="$1"
  if guidance="$(test_environment_guidance "$status")"; then
    printf '%s. Next step: %s\n' "$status" "$guidance"
    return 0
  fi

  printf '%s\n' "$status"
}

run_xcodebuild_logged() {
  local log_path action_status failure_summary
  log_path="$(mktemp -t skillbar-xcodebuild)"

  set +e
  "$@" 2>&1 | tee "$log_path"
  action_status=${PIPESTATUS[0]}
  set -e

  if [[ $action_status -eq 0 ]]; then
    rm -f "$log_path"
    return 0
  fi

  if failure_summary="$(summarize_xcodebuild_failure "$log_path")"; then
    die "$failure_summary. Full log: $log_path"
  fi

  die "xcodebuild failed. Full log: $log_path"
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

test_environment_status() {
  local probe_log probe_status failure_summary

  if [[ "${SKILLBAR_FORCE_TEST:-0}" != "1" && "${CODEX_SANDBOX:-}" == "seatbelt" ]]; then
    printf 'Codex seatbelt sandbox blocks the macOS test runner in this session\n'
    return 1
  fi

  probe_log="$(mktemp -t skillbar-test-env)"

  set +e
  DEVELOPER_DIR="$XCODE_DIR" xcodebuild \
    -project "$WORKSPACE/$PROJECT_NAME" \
    -scheme "$SCHEME" \
    -destination 'platform=macOS' \
    -showdestinations >"$probe_log" 2>&1
  probe_status=$?
  set -e

  if failure_summary="$(summarize_xcodebuild_failure "$probe_log")"; then
    printf '%s\n' "$failure_summary"
    return 1
  fi

  if [[ $probe_status -eq 0 ]]; then
    rm -f "$probe_log"
    printf 'ready\n'
    return 0
  fi

  printf 'probe failed (inspect: %s)\n' "$probe_log"
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
  printf 'Test environment: '
  local environment_status
  if environment_status="$(test_environment_status)"; then
    print_test_environment_status "$environment_status"
  else
    print_test_environment_status "$environment_status"
  fi
}

inspect_workspace() {
  ensure_workspace

  local repo_root
  repo_root="$(resolve_repo_root)"

  printf 'Workspace: %s\n' "$WORKSPACE"
  printf 'Main files:\n'
  printf -- '- %s/scripts/run_skillbar.sh\n' "$repo_root"
  printf -- '  repo-root wrapper for the packaged SkillBar runner\n'
  printf -- '- %s/references/project-map.md\n' "$repo_root/skills/skillbar"
  printf -- '- %s/project.yml\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Info.plist\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Sources/App/SkillBarApp.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Sources/App/SkillBarModel.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Sources/Models/SkillBarModels.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Sources/Services/SkillCatalogService.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Sources/Services/SkillInstallService.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Sources/Views/MenuBarView.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Sources/Views/SkillBarMenuIcon.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Tests/SkillCatalogServiceTests.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Tests/SkillBarModelTests.swift\n' "$WORKSPACE"
  printf -- '- %s/SkillBarApp/Tests/SkillInstallServiceExecutionTests.swift\n' "$WORKSPACE"
  printf -- '- %s/bin/codex-goated\n' "$repo_root"
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
    run_xcodebuild_logged env DEVELOPER_DIR="$XCODE_DIR" xcodebuild \
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

  printf 'Typecheck OK: %s Swift source files in %s\n' "${#sources[@]}" "$WORKSPACE/SkillBarApp/Sources"
}

test_project() {
  require_tool xcodegen
  require_tool swiftc
  require_tool xcodebuild
  ensure_workspace
  [[ -d "$WORKSPACE/$PROJECT_NAME" ]] || generate_project
  ensure_xcode_ready

  local environment_status
  if ! environment_status="$(test_environment_status)"; then
    if ! test_environment_allows_macos_tests "$environment_status"; then
      die "$(format_test_environment_error "$environment_status")"
    fi
  fi

  (
    cd "$WORKSPACE" &&
    run_xcodebuild_logged env DEVELOPER_DIR="$XCODE_DIR" xcodebuild \
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
