#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WORKSPACE=""
APP_DIR=""
HELPER_SCRIPT="$SCRIPT_DIR/fetch_on_this_day.py"
PORT="${PORT:-4173}"
PID_FILE="${TMPDIR:-/tmp}/on-this-day-preview.pid"
LOG_FILE="${TMPDIR:-/tmp}/on-this-day-preview.log"

usage() {
  cat <<'EOF'
Usage:
  run_on_this_day.sh [--workspace PATH] <doctor|inspect|fetch|serve|run|stop>

Commands:
  doctor     Check local prerequisites and workspace shape
  inspect    Print the main On This Day web files for quick orientation
  fetch      Run the deterministic Wikimedia feed helper
  serve      Start a local preview server in the foreground
  run        Start or reuse a preview server, then open the browser
  stop       Stop the background preview server started by run

Examples:
  bash run_on_this_day.sh doctor
  bash run_on_this_day.sh fetch --date 2026-03-27 --type selected --limit 5
  bash run_on_this_day.sh --workspace /path/to/apps/on-this-day run
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

resolve_workspace() {
  local candidate

  if [[ -n "$WORKSPACE" ]]; then
    if [[ -f "$WORKSPACE/index.html" && -f "$WORKSPACE/app.js" && -f "$WORKSPACE/styles.css" ]]; then
      APP_DIR="$WORKSPACE"
      return 0
    fi

    if [[ -f "$WORKSPACE/apps/on-this-day/index.html" ]]; then
      APP_DIR="$WORKSPACE/apps/on-this-day"
      return 0
    fi

    die "Workspace not found: $WORKSPACE"
  fi

  for candidate in \
    "$PWD" \
    "$PWD/apps/on-this-day" \
    "$SCRIPT_DIR/../../../apps/on-this-day"
  do
    if [[ -f "$candidate/index.html" && -f "$candidate/app.js" && -f "$candidate/styles.css" ]]; then
      APP_DIR="$candidate"
      return 0
    fi
  done

  die "Could not find the On This Day workspace. Re-run with --workspace /path/to/apps/on-this-day."
}

ensure_workspace() {
  if [[ -z "$APP_DIR" ]]; then
    resolve_workspace
  fi

  [[ -d "$APP_DIR" ]] || die "Workspace not found: $APP_DIR"
  [[ -f "$APP_DIR/README.md" ]] || die "Missing README.md in $APP_DIR"
  [[ -f "$APP_DIR/index.html" ]] || die "Missing index.html in $APP_DIR"
  [[ -f "$APP_DIR/app.js" ]] || die "Missing app.js in $APP_DIR"
  [[ -f "$APP_DIR/styles.css" ]] || die "Missing styles.css in $APP_DIR"
  [[ -f "$HELPER_SCRIPT" ]] || die "Missing helper script: $HELPER_SCRIPT"
}

doctor() {
  ensure_workspace
  printf 'Workspace: %s\n' "$APP_DIR"
  printf 'python3: %s\n' "$(python3 --version 2>&1)"
  printf 'Browser opener: %s\n' "$(command -v open >/dev/null 2>&1 && echo present || echo missing)"
  printf 'Preview URL: http://localhost:%s\n' "$PORT"
  printf 'Helper script: %s\n' "$HELPER_SCRIPT"
}

inspect_workspace() {
  ensure_workspace
  cat <<EOF
Workspace: $APP_DIR
Main files:
- $APP_DIR/README.md
- $APP_DIR/index.html
- $APP_DIR/app.js
- $APP_DIR/styles.css
- $HELPER_SCRIPT
EOF
}

fetch_feed() {
  ensure_workspace
  python3 "$HELPER_SCRIPT" "$@"
}

server_pid() {
  [[ -f "$PID_FILE" ]] || return 1
  local pid
  pid="$(cat "$PID_FILE" 2>/dev/null || true)"
  [[ -n "$pid" ]] || return 1
  kill -0 "$pid" >/dev/null 2>&1 || return 1
  printf '%s\n' "$pid"
}

wait_for_server() {
  local attempt=0

  while [[ "$attempt" -lt 40 ]]; do
    if python3 - "$PORT" <<'PY'
import sys
import urllib.request

port = sys.argv[1]
try:
    with urllib.request.urlopen(f"http://127.0.0.1:{port}/", timeout=1) as response:
        raise SystemExit(0 if response.status < 400 else 1)
except Exception:
    raise SystemExit(1)
PY
    then
      return 0
    fi

    attempt=$((attempt + 1))
    sleep 0.25
  done

  return 1
}

start_server_background() {
  ensure_workspace

  if server_pid >/dev/null 2>&1; then
    return 0
  fi

  rm -f "$PID_FILE" "$LOG_FILE"
  nohup python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$APP_DIR" >"$LOG_FILE" 2>&1 &
  echo $! >"$PID_FILE"
  if wait_for_server; then
    return 0
  fi

  rm -f "$PID_FILE"
  return 1
}

serve_foreground() {
  ensure_workspace
  exec python3 -m http.server "$PORT" --bind 127.0.0.1 --directory "$APP_DIR"
}

run_preview() {
  if start_server_background; then
    if command -v open >/dev/null 2>&1 && open "http://localhost:$PORT" >/dev/null 2>&1; then
      :
    else
      printf 'Open http://localhost:%s\n' "$PORT"
    fi
    printf 'Preview server: http://localhost:%s\n' "$PORT"
    printf 'PID file: %s\n' "$PID_FILE"
    printf 'Log file: %s\n' "$LOG_FILE"
  else
    printf 'Preview server could not start here, so opening index.html directly.\n'
    if command -v open >/dev/null 2>&1 && open "$APP_DIR/index.html" >/dev/null 2>&1; then
      :
    else
      printf 'Open %s\n' "$APP_DIR/index.html"
    fi
    printf 'Direct file: %s\n' "$APP_DIR/index.html"
    printf 'Log file: %s\n' "$LOG_FILE"
  fi
}

stop_preview() {
  local pid
  if pid="$(server_pid)"; then
    kill "$pid" >/dev/null 2>&1 || true
    rm -f "$PID_FILE"
    printf 'Stopped preview server (pid %s)\n' "$pid"
  else
    rm -f "$PID_FILE"
    printf 'No preview server is running.\n'
  fi
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
    doctor|inspect|fetch|serve|run|stop)
      break
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

COMMAND="${1:-}"
[[ -n "$COMMAND" ]] || { usage; exit 1; }
shift || true

case "$COMMAND" in
  doctor)
    doctor
    ;;
  inspect)
    inspect_workspace
    ;;
  fetch)
    fetch_feed "$@"
    ;;
  serve)
    serve_foreground
    ;;
  run)
    run_preview
    ;;
  stop)
    stop_preview
    ;;
  *)
    die "Unknown command: $COMMAND"
    ;;
esac
