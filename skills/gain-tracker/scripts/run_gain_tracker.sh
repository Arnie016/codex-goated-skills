#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CONFIG_PATH="${CODEX_HOME:-$HOME/.codex}/gain-tracker/config.json"
GITHUB_CONNECT="$SCRIPT_DIR/github_connect.py"
DAILY_STORY="$SCRIPT_DIR/daily_git_story.py"
GIT_GAIN="$SCRIPT_DIR/git_gain.py"
GAIN_MATH="$SCRIPT_DIR/gain_math.py"

usage() {
  cat <<'EOF'
Usage:
  run_gain_tracker.sh <command> [args...]

Commands:
  doctor        Check local prerequisites, config state, and repo context
  inspect       Print the main gain-tracker files and command lanes
  status        Show saved GitHub and tracked-repo status
  connect       Connect through gh and optionally track repos
  track-repo    Add one tracked repository
  track-dir     Scan a folder and track GitHub repos
  untrack-repo  Remove one tracked repository
  daily         Run the daily git story helper
  compare       Run the git window comparison helper
  math          Run the manual multiplier calculator
  validate      Run lightweight local validation for the skill scripts

Examples:
  bash run_gain_tracker.sh doctor
  bash run_gain_tracker.sh status
  bash run_gain_tracker.sh connect --track-cwd
  bash run_gain_tracker.sh track-dir --dir ~/Desktop --max-depth 2
  bash run_gain_tracker.sh daily --repo /path/to/repo --target-multiplier 90
  bash run_gain_tracker.sh compare --repo /path/to/repo --baseline-since 2024-01-01 --baseline-until 2024-01-31 --current-since 2026-03-01 --current-until 2026-03-29 --goal-multiplier 10
  bash run_gain_tracker.sh math --baseline-output 12 --baseline-days 6 --current-output 40 --current-days 5 --goal-multiplier 4
  bash run_gain_tracker.sh validate
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

tool_status() {
  local resolved=""
  resolved="$(command -v "$1" 2>/dev/null || true)"
  if [[ -n "$resolved" ]]; then
    printf '%s' "$resolved"
  else
    printf 'missing'
  fi
}

require_python() {
  command -v python3 >/dev/null 2>&1 || die "python3 is required."
}

current_repo_root() {
  if command -v git >/dev/null 2>&1 && git -C "$PWD" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$PWD" rev-parse --show-toplevel
  fi
}

gh_auth_state() {
  if ! command -v gh >/dev/null 2>&1; then
    printf 'gh not installed\n'
    return 0
  fi

  if gh auth status >/dev/null 2>&1; then
    printf 'authenticated\n'
  else
    printf 'not authenticated or unavailable\n'
  fi
}

doctor() {
  local repo_root=""
  repo_root="$(current_repo_root || true)"

  printf 'Skill dir: %s\n' "$SKILL_DIR"
  printf 'Runner: %s\n' "$SCRIPT_DIR/run_gain_tracker.sh"
  printf 'python3: %s\n' "$(tool_status python3)"
  printf 'git: %s\n' "$(tool_status git)"
  if command -v gh >/dev/null 2>&1; then
    printf 'gh: %s\n' "$(tool_status gh)"
  else
    printf 'gh: missing (connect commands will not work)\n'
  fi
  printf 'gh auth: %s\n' "$(gh_auth_state)"
  printf 'Config path: %s\n' "$CONFIG_PATH"
  printf 'Config file: %s\n' "$([[ -f "$CONFIG_PATH" ]] && printf 'present' || printf 'not created yet')"
  printf 'Current repo: %s\n' "${repo_root:-not a git repo}"
  printf 'Python helpers: '
  if [[ -f "$GITHUB_CONNECT" && -f "$DAILY_STORY" && -f "$GIT_GAIN" && -f "$GAIN_MATH" ]]; then
    printf 'present\n'
  else
    printf 'missing expected helper script(s)\n'
  fi

  if command -v python3 >/dev/null 2>&1; then
    printf '\nSaved status:\n'
    python3 "$GITHUB_CONNECT" status || true
  fi
}

inspect() {
  cat <<EOF
Skill: gain-tracker
Main files:
- $SKILL_DIR/SKILL.md
- $GITHUB_CONNECT
- $DAILY_STORY
- $GIT_GAIN
- $GAIN_MATH
- $SCRIPT_DIR/tracker_config.py
- $SKILL_DIR/references/product-spec.md

Command lanes:
- doctor: environment, gh, config, and repo readiness
- status: saved GitHub identity and tracked repositories
- connect / track-repo / track-dir / untrack-repo: repo tracking setup
- daily: today's work, 7-day momentum, 30-day momentum, and reminder story
- compare: baseline-versus-current git window comparison
- math: manual multiplier and goal-progress calculator
- validate: py_compile plus a deterministic math smoke test
EOF
}

status() {
  require_python
  python3 "$GITHUB_CONNECT" status "$@"
}

connect() {
  require_python
  python3 "$GITHUB_CONNECT" connect "$@"
}

track_repo() {
  require_python
  python3 "$GITHUB_CONNECT" track-repo "$@"
}

track_dir() {
  require_python
  python3 "$GITHUB_CONNECT" track-dir "$@"
}

untrack_repo() {
  require_python
  python3 "$GITHUB_CONNECT" untrack-repo "$@"
}

daily() {
  require_python
  python3 "$DAILY_STORY" "$@"
}

compare() {
  require_python
  python3 "$GIT_GAIN" "$@"
}

math() {
  require_python
  python3 "$GAIN_MATH" "$@"
}

validate() {
  require_python
  python3 -m py_compile "$SCRIPT_DIR"/*.py
  python3 "$GAIN_MATH" \
    --baseline-output 10 \
    --baseline-days 5 \
    --current-output 35 \
    --current-days 5 \
    --goal-multiplier 4 \
    --label "gain-tracker-smoke" \
    --metric "commits" \
    >/dev/null
  printf 'Validation OK: py_compile and math smoke test passed.\n'
}

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] || {
  usage
  exit 1
}
shift || true

case "$COMMAND" in
  doctor)
    doctor "$@"
    ;;
  inspect)
    inspect "$@"
    ;;
  status)
    status "$@"
    ;;
  connect)
    connect "$@"
    ;;
  track-repo)
    track_repo "$@"
    ;;
  track-dir)
    track_dir "$@"
    ;;
  untrack-repo)
    untrack_repo "$@"
    ;;
  daily)
    daily "$@"
    ;;
  compare)
    compare "$@"
    ;;
  math)
    math "$@"
    ;;
  validate)
    validate "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    die "Unknown command: $COMMAND"
    ;;
esac
