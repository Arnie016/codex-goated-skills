#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="$PWD"
REPO_ROOT=""
WORKSPACE_TYPE=""
PROJECT_SPEC=""
PROJECT_FILE=""
PROJECT_NAME=""
SCHEME_NAME=""
PAIRED_RUNNER=""
XCODE_STATUS="not checked"
XCODE_DETAIL=""
XCODE_LOG="/tmp/workspace-doctor-xcode-$$.log"
CATALOG_STATUS="not checked"
CATALOG_DETAIL=""

usage() {
  cat <<'EOF'
Usage:
  workspace_doctor.sh [--workspace PATH]
  workspace_doctor.sh [PATH]

Examples:
  bash workspace_doctor.sh
  bash workspace_doctor.sh --workspace apps/flight-scout
  bash workspace_doctor.sh /path/to/project
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

normalize_dir() {
  local target="$1"
  [[ -d "$target" ]] || die "Workspace not found: $target"
  (cd "$target" && pwd)
}

section() {
  printf '\n%s\n' "$1"
}

item() {
  printf -- '- %s\n' "$1"
}

marker_item() {
  local label="$1"
  local path="$2"
  if [[ -e "$path" ]]; then
    item "$label: present"
  else
    item "$label: missing"
  fi
}

find_repo_root() {
  local dir="$1"
  while [[ -n "$dir" && "$dir" != "/" ]]; do
    if [[ -d "$dir/skills" && -d "$dir/apps" && -f "$dir/bin/codex-goated" ]]; then
      printf '%s\n' "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done
  return 1
}

detect_workspace_type() {
  if [[ -d "$WORKSPACE/apps" && -d "$WORKSPACE/skills" && -f "$WORKSPACE/bin/codex-goated" ]]; then
    WORKSPACE_TYPE="repo-root"
    return
  fi

  if [[ -f "$WORKSPACE/project.yml" ]]; then
    WORKSPACE_TYPE="xcodegen-app"
    return
  fi

  if [[ -f "$WORKSPACE/package.json" ]]; then
    WORKSPACE_TYPE="node-project"
    return
  fi

  if [[ -f "$WORKSPACE/pyproject.toml" || -f "$WORKSPACE/requirements.txt" || -f "$WORKSPACE/uv.lock" ]]; then
    WORKSPACE_TYPE="python-project"
    return
  fi

  WORKSPACE_TYPE="generic"
}

detect_project_details() {
  local scheme_path

  if [[ -f "$WORKSPACE/project.yml" ]]; then
    PROJECT_SPEC="$WORKSPACE/project.yml"
    PROJECT_NAME="$(awk '/^name:[[:space:]]*/ {sub(/^name:[[:space:]]*/, "", $0); print; exit}' "$PROJECT_SPEC")"
  fi

  PROJECT_FILE="$(find "$WORKSPACE" -maxdepth 1 -type d -name '*.xcodeproj' | sort | head -n 1)"
  if [[ -n "$PROJECT_FILE" && -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME="$(basename "$PROJECT_FILE" .xcodeproj)"
  fi

  scheme_path="$(find "$WORKSPACE" -path '*/xcshareddata/xcschemes/*.xcscheme' -type f | sort | head -n 1)"
  if [[ -n "$scheme_path" ]]; then
    SCHEME_NAME="$(basename "$scheme_path" .xcscheme)"
  elif [[ -n "$PROJECT_NAME" ]]; then
    SCHEME_NAME="$PROJECT_NAME"
  fi

  if [[ -n "$REPO_ROOT" && "$WORKSPACE_TYPE" == "xcodegen-app" ]]; then
    PAIRED_RUNNER="$(find_paired_runner "$(basename "$WORKSPACE")" "$PROJECT_NAME" "$WORKSPACE" || true)"
  fi
}

tool_version() {
  local tool="$1"
  case "$tool" in
    git)
      git --version 2>&1 | head -n 1
      ;;
    node)
      node --version 2>&1 | head -n 1
      ;;
    npm|pnpm|bun|uv|docker|gh|xcodegen)
      "$tool" --version 2>&1 | head -n 1
      ;;
    go)
      go version 2>&1 | head -n 1
      ;;
    python3)
      python3 --version 2>&1 | head -n 1
      ;;
    pip)
      pip --version 2>&1 | head -n 1
      ;;
    cargo)
      cargo --version 2>&1 | head -n 1
      ;;
    xcodebuild)
      xcodebuild -version 2>&1 | head -n 1
      ;;
    swiftc)
      swiftc --version 2>&1 | head -n 1
      ;;
    *)
      printf 'present\n'
      ;;
  esac
}

print_tool() {
  local tool="$1"
  if command -v "$tool" >/dev/null 2>&1; then
    item "$tool: $(tool_version "$tool")"
  else
    item "$tool: missing"
  fi
}

parse_xcode_failure() {
  if grep -qi "license" "$XCODE_LOG" 2>/dev/null; then
    XCODE_STATUS="license not accepted"
    XCODE_DETAIL="run: sudo xcodebuild -license"
    return
  fi

  if grep -Eqi "runFirstLaunch|failed to load a required plug-in|failed to load code for plug-in" "$XCODE_LOG" 2>/dev/null; then
    XCODE_STATUS="runFirstLaunch needed"
    XCODE_DETAIL="run: sudo xcodebuild -runFirstLaunch"
    return
  fi

  XCODE_STATUS="not ready"
  XCODE_DETAIL="$(head -n 1 "$XCODE_LOG" | tr -d '\r')"
  [[ -n "$XCODE_DETAIL" ]] || XCODE_DETAIL="inspect $XCODE_LOG for details"
}

check_xcode_state() {
  local probe_project=""
  local saw_repo_probe=0

  if ! command -v xcodebuild >/dev/null 2>&1; then
    XCODE_STATUS="missing"
    XCODE_DETAIL="xcodebuild is not available on this Mac"
    return
  fi

  if xcodebuild -version >"$XCODE_LOG" 2>&1; then
    XCODE_STATUS="ready"
    XCODE_DETAIL="$(head -n 1 "$XCODE_LOG" | tr -d '\r')"
  else
    parse_xcode_failure
    return
  fi

  if [[ "$WORKSPACE_TYPE" == "repo-root" ]]; then
    while IFS= read -r candidate; do
      [[ -n "$candidate" ]] || continue
      if ! path_is_tracked "${candidate#$REPO_ROOT/}/project.pbxproj"; then
        continue
      fi
      saw_repo_probe=1
      if xcodebuild -list -project "$candidate" >"$XCODE_LOG" 2>&1; then
        probe_project="$candidate"
        continue
      fi
      parse_xcode_failure
      return
    done < <(find "$WORKSPACE/apps" -path '*/xcshareddata/xcschemes/*.xcscheme' -type f | sort | sed 's#/xcshareddata/xcschemes/.*$#.xcodeproj#' | uniq)

    if [[ "$saw_repo_probe" -eq 1 ]]; then
      XCODE_STATUS="ready"
      if [[ -n "$probe_project" ]]; then
        XCODE_DETAIL="xcodebuild can inspect tracked app projects, including $(basename "$probe_project")"
      else
        XCODE_DETAIL="xcodebuild can inspect tracked app projects"
      fi
    fi
    return
  fi

  if [[ -n "$PROJECT_FILE" ]]; then
    probe_project="$PROJECT_FILE"
  fi

  if [[ -n "$probe_project" ]]; then
    if xcodebuild -list -project "$probe_project" >"$XCODE_LOG" 2>&1; then
      XCODE_STATUS="ready"
      XCODE_DETAIL="xcodebuild can inspect $(basename "$probe_project")"
    else
      parse_xcode_failure
    fi
  fi
}

check_catalog_state() {
  CATALOG_STATUS="not checked"
  CATALOG_DETAIL=""

  [[ -n "$REPO_ROOT" ]] || return 0

  if [[ ! -f "$REPO_ROOT/scripts/build-catalog.py" ]]; then
    CATALOG_STATUS="missing"
    CATALOG_DETAIL="scripts/build-catalog.py is missing"
    return 0
  fi

  if [[ ! -f "$REPO_ROOT/catalog/index.json" ]]; then
    CATALOG_STATUS="missing"
    CATALOG_DETAIL="catalog/index.json is missing"
    return 0
  fi

  if ! command -v python3 >/dev/null 2>&1; then
    CATALOG_STATUS="skipped"
    CATALOG_DETAIL="python3 is missing, so catalog freshness could not be checked"
    return 0
  fi

  if python3 "$REPO_ROOT/scripts/build-catalog.py" --repo-dir "$REPO_ROOT" --check >/dev/null 2>&1; then
    CATALOG_STATUS="current"
    CATALOG_DETAIL="catalog/index.json matches the current skill and pack files"
  else
    CATALOG_STATUS="stale"
    CATALOG_DETAIL="run: bash $REPO_ROOT/bin/codex-goated catalog build --repo-dir $REPO_ROOT"
  fi
}

path_is_tracked() {
  local repo_relative="$1"
  if [[ -d "$REPO_ROOT/.git" ]] && command -v git >/dev/null 2>&1; then
    git -C "$REPO_ROOT" ls-files --error-unmatch -- "$repo_relative" >/dev/null 2>&1
  else
    return 0
  fi
}

find_paired_runner() {
  local app_name="$1"
  local project_name="$2"
  local workspace_path="${3:-$WORKSPACE}"
  local runner best_runner="" score best_score=0 marker

  while IFS= read -r runner; do
    [[ -n "$runner" ]] || continue
    score=0
    if grep -Eq "apps/$app_name" "$runner"; then
      score=$((score + 3))
    fi
    if [[ -n "$project_name" ]] && grep -Eq "${project_name}(\\.xcodeproj|App|Widget|Tests|Settings)" "$runner"; then
      score=$((score + 5))
    fi
    if [[ -n "$workspace_path" && -d "$workspace_path" ]]; then
      while IFS= read -r marker; do
        [[ -n "$marker" ]] || continue
        if grep -Fq "$marker" "$runner"; then
          score=$((score + 2))
        fi
      done < <(find "$workspace_path" -mindepth 1 -maxdepth 1 -type d | sed 's#.*/##' | sort)
    fi
    if [[ "$score" -gt "$best_score" ]]; then
      best_score="$score"
      best_runner="$runner"
    fi
  done < <(find "$REPO_ROOT/skills" -path '*/scripts/run_*.sh' -type f | sort)

  if [[ "$best_score" -gt 0 && -n "$best_runner" ]]; then
    printf '%s\n' "$best_runner"
    return 0
  fi

  return 1
}

preferred_root_workspace() {
  local candidate app_dir app_name

  candidate="$REPO_ROOT/apps/skillbar"
  if [[ -d "$candidate" && -f "$candidate/project.yml" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  while IFS= read -r app_dir; do
    [[ -n "$app_dir" ]] || continue
    if ! path_is_tracked "${app_dir#$REPO_ROOT/}/project.yml"; then
      continue
    fi
    app_name="$(basename "$app_dir")"
    if find_paired_runner "$app_name" "" "$app_dir" >/dev/null 2>&1; then
      printf '%s\n' "$app_dir"
      return 0
    fi
  done < <(find "$REPO_ROOT/apps" -mindepth 1 -maxdepth 1 -type d | sort)

  return 1
}

print_tracked_app_runner_inventory() {
  local app_dir app_name runner printed_any=0 missing_any=0

  while IFS= read -r app_dir; do
    [[ -n "$app_dir" ]] || continue
    app_name="$(basename "$app_dir")"
    if ! path_is_tracked "${app_dir#$REPO_ROOT/}/project.yml"; then
      continue
    fi
    runner="$(find_paired_runner "$app_name" "" "$app_dir" 2>/dev/null || true)"
    if [[ -n "$runner" ]]; then
      if [[ "$printed_any" -eq 0 ]]; then
        item "tracked app workspaces and runner commands:"
        printed_any=1
      fi
      printf '  - %s -> bash %s doctor\n' "$app_name" "$runner"
      continue
    fi

    if [[ "$missing_any" -eq 0 ]]; then
      item "tracked app workspaces without a detected paired runner:"
      missing_any=1
    fi
    printf '  - %s\n' "$app_name"
  done < <(find "$REPO_ROOT/apps" -mindepth 1 -maxdepth 1 -type d | sort)

  if [[ "$printed_any" -eq 0 && "$missing_any" -eq 0 ]]; then
    item "no tracked app workspaces found"
  fi
}

print_marker_summary() {
  section "Markers"
  marker_item ".git" "$WORKSPACE/.git"
  marker_item "package.json" "$WORKSPACE/package.json"
  marker_item "pyproject.toml" "$WORKSPACE/pyproject.toml"
  marker_item "requirements.txt" "$WORKSPACE/requirements.txt"
  marker_item "uv.lock" "$WORKSPACE/uv.lock"
  marker_item "Cargo.toml" "$WORKSPACE/Cargo.toml"
  marker_item "go.mod" "$WORKSPACE/go.mod"
  marker_item "project.yml" "$WORKSPACE/project.yml"
  marker_item "Dockerfile" "$WORKSPACE/Dockerfile"
  marker_item "docker-compose.yml" "$WORKSPACE/docker-compose.yml"
  marker_item "scripts/" "$WORKSPACE/scripts"
  marker_item "bin/" "$WORKSPACE/bin"
}

print_toolchain_summary() {
  section "Toolchain"
  print_tool git
  print_tool python3
  print_tool pip
  print_tool node
  print_tool npm
  print_tool pnpm
  print_tool bun
  print_tool uv
  print_tool cargo
  print_tool go
  print_tool docker
  print_tool gh
  print_tool xcodegen
  print_tool swiftc
  print_tool xcodebuild
  item "xcode status: $XCODE_STATUS${XCODE_DETAIL:+ ($XCODE_DETAIL)}"
}

print_app_workspace_summary() {
  section "App Workspace"
  item "workspace type: $WORKSPACE_TYPE"
  [[ -n "$PROJECT_SPEC" ]] && item "project spec: $PROJECT_SPEC"
  [[ -n "$PROJECT_FILE" ]] && item "xcode project: $PROJECT_FILE"
  [[ -n "$SCHEME_NAME" ]] && item "scheme: $SCHEME_NAME"
  if [[ -n "$PAIRED_RUNNER" ]]; then
    item "paired runner: $PAIRED_RUNNER"
  else
    item "paired runner: none detected"
  fi
}

print_repo_summary() {
  section "Repo Entry Points"
  if [[ -f "$REPO_ROOT/bin/codex-goated" ]]; then
    item "cli: bash $REPO_ROOT/bin/codex-goated"
  fi
  if [[ -f "$REPO_ROOT/scripts/audit-catalog.sh" ]]; then
    item "catalog audit: bash $REPO_ROOT/scripts/audit-catalog.sh --repo-dir $REPO_ROOT"
  fi
  item "catalog index: $CATALOG_STATUS${CATALOG_DETAIL:+ ($CATALOG_DETAIL)}"

  if [[ "$WORKSPACE_TYPE" == "repo-root" ]]; then
    print_tracked_app_runner_inventory
  fi
}

print_blockers() {
  local printed=0

  section "Likely Blockers"

  if [[ "$WORKSPACE_TYPE" == "xcodegen-app" && ! -f "$WORKSPACE/project.yml" ]]; then
    item "This app workspace is missing project.yml."
    printed=1
  fi

  if [[ -f "$WORKSPACE/project.yml" ]] && ! command -v xcodegen >/dev/null 2>&1; then
    item "xcodegen is missing, so this workspace cannot regenerate its Xcode project."
    printed=1
  fi

  if [[ "$WORKSPACE_TYPE" == "xcodegen-app" || "$WORKSPACE_TYPE" == "repo-root" ]]; then
    if [[ "$XCODE_STATUS" != "ready" ]]; then
      item "Xcode is not fully ready: $XCODE_STATUS${XCODE_DETAIL:+ ($XCODE_DETAIL)}"
      printed=1
    fi
  fi

  if [[ "$WORKSPACE_TYPE" == "xcodegen-app" && -z "$PAIRED_RUNNER" && -n "$REPO_ROOT" ]]; then
    item "No paired skill runner was detected for $(basename "$WORKSPACE")."
    printed=1
  fi

  case "$CATALOG_STATUS" in
    stale|missing)
      item "Generated catalog is not current: $CATALOG_DETAIL"
      printed=1
      ;;
  esac

  if [[ "$printed" -eq 0 ]]; then
    item "No obvious machine-level blocker detected from the local audit."
  fi
}

print_recommendations() {
  local app_name focus_workspace=""

  section "Recommended Next Commands"

  case "$CATALOG_STATUS" in
    stale|missing)
      item "bash $REPO_ROOT/bin/codex-goated catalog build --repo-dir $REPO_ROOT"
      ;;
  esac

  case "$WORKSPACE_TYPE" in
    repo-root)
      if [[ -f "$WORKSPACE/bin/codex-goated" ]]; then
        item "bash $WORKSPACE/bin/codex-goated audit --repo-dir $WORKSPACE"
      fi
      if [[ -f "$WORKSPACE/scripts/audit-catalog.sh" ]]; then
        item "bash $WORKSPACE/scripts/audit-catalog.sh --repo-dir $WORKSPACE"
      fi
      if [[ -f "$WORKSPACE/skills/workspace-doctor/scripts/workspace_doctor.sh" ]]; then
        if focus_workspace="$(preferred_root_workspace)"; then
          item "bash $WORKSPACE/skills/workspace-doctor/scripts/workspace_doctor.sh --workspace $focus_workspace"
        fi
      fi
      ;;
    xcodegen-app)
      if [[ -n "$PAIRED_RUNNER" ]]; then
        item "bash $PAIRED_RUNNER doctor"
        if grep -Eq 'inspect' "$PAIRED_RUNNER"; then
          item "bash $PAIRED_RUNNER inspect"
        fi
        if grep -Eq 'test' "$PAIRED_RUNNER"; then
          item "bash $PAIRED_RUNNER test"
        elif grep -Eq 'typecheck' "$PAIRED_RUNNER"; then
          item "bash $PAIRED_RUNNER typecheck"
        else
          item "bash $PAIRED_RUNNER build"
        fi
      else
        app_name="$(basename "$WORKSPACE")"
        if [[ -f "$WORKSPACE/project.yml" ]]; then
          item "cd $WORKSPACE && xcodegen generate"
        fi
        if [[ -n "$PROJECT_FILE" && -n "$SCHEME_NAME" ]]; then
          item "cd $WORKSPACE && xcodebuild -project $(basename "$PROJECT_FILE") -scheme $SCHEME_NAME -destination 'platform=macOS' test"
        elif [[ -n "$PROJECT_NAME" ]]; then
          item "Inspect $WORKSPACE/project.yml and add a paired runner for $app_name if this app should be a first-class repo skill."
        fi
      fi
      ;;
    node-project)
      item "Inspect package.json scripts and run the smallest doctor/build/test command that confirms the blocker."
      ;;
    python-project)
      item "Inspect pyproject.toml or requirements.txt and run the lightest environment check before deeper code changes."
      ;;
    *)
      item "Start with the smallest local command that reproduces the problem and confirm the workspace entrypoint first."
      ;;
  esac
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
      if [[ $# -eq 1 && -d "$1" ]]; then
        WORKSPACE="$1"
        shift
      else
        die "Unknown argument: $1"
      fi
      ;;
  esac
done

trap 'rm -f "$XCODE_LOG"' EXIT

WORKSPACE="$(normalize_dir "$WORKSPACE")"
REPO_ROOT="$(find_repo_root "$WORKSPACE" || true)"
detect_workspace_type
detect_project_details
check_xcode_state
check_catalog_state

printf 'Workspace: %s\n' "$WORKSPACE"
printf 'Workspace type: %s\n' "$WORKSPACE_TYPE"
if [[ -n "$REPO_ROOT" ]]; then
  printf 'Repo root: %s\n' "$REPO_ROOT"
fi

print_marker_summary
print_toolchain_summary

if [[ "$WORKSPACE_TYPE" == "xcodegen-app" ]]; then
  print_app_workspace_summary
fi

if [[ -n "$REPO_ROOT" ]]; then
  print_repo_summary
fi

print_blockers
print_recommendations
