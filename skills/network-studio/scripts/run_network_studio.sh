#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALLER="$SCRIPT_DIR/install_network_studio.py"
TEMPLATE_DIR="$SKILL_DIR/assets/workspace"
DEFAULT_WORKSPACE="$HOME/Network Studio"
WORKSPACE=""
SWIFTBAR_PLUGINS_DIR=""
PLUGIN_NAME="network-studio.1m.sh"
COMMAND=""
COMMAND_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  run_network_studio.sh [--workspace PATH] [--swiftbar-plugins-dir PATH] [--plugin-name NAME] <command> [args...]

Commands:
  doctor     Check prerequisites, template layout, and installed workspace shape
  inspect    Print the main portable workspace files and helper commands
  install    Install or refresh the portable workspace
  refresh    Rebuild the dashboard and SwiftBar output
  open       Refresh the dashboard and open it in the browser
  watch      Run the continuous network watcher

Examples:
  bash run_network_studio.sh doctor
  bash run_network_studio.sh install ~/Network\ Studio
  bash run_network_studio.sh --swiftbar-plugins-dir ~/SwiftBarPlugins install ~/Network\ Studio
  bash run_network_studio.sh --workspace ~/Network\ Studio refresh --scan
  bash run_network_studio.sh --workspace ~/Network\ Studio watch --interval 30 --resolve
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

workspace_has_install() {
  local workspace="$1"
  [[ -f "$workspace/network-watch.sh" ]] && \
    [[ -f "$workspace/.swiftbar-support/open-network-studio.sh" ]] && \
    [[ -d "$workspace/swiftbar" ]]
}

find_installed_workspace() {
  local candidate
  for candidate in \
    "${WORKSPACE:-}" \
    "$PWD" \
    "$PWD/Network Studio" \
    "$DEFAULT_WORKSPACE"
  do
    [[ -n "$candidate" ]] || continue
    if [[ -d "$candidate" ]] && workspace_has_install "$candidate"; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

resolve_workspace() {
  if [[ -n "$WORKSPACE" ]]; then
    return 0
  fi

  if WORKSPACE="$(find_installed_workspace 2>/dev/null)"; then
    return 0
  fi

  WORKSPACE="$DEFAULT_WORKSPACE"
}

ensure_workspace_arg() {
  resolve_workspace
  [[ -n "$WORKSPACE" ]] || die "Unable to resolve a workspace path."
}

install_workspace() {
  require_tool python3
  [[ -d "$TEMPLATE_DIR" ]] || die "Missing template directory: $TEMPLATE_DIR"
  ensure_workspace_arg

  local installer_args=("$INSTALLER" "$WORKSPACE")
  if [[ -n "$SWIFTBAR_PLUGINS_DIR" ]]; then
    installer_args+=(--swiftbar-plugins-dir "$SWIFTBAR_PLUGINS_DIR")
  fi
  if [[ -n "$PLUGIN_NAME" ]]; then
    installer_args+=(--plugin-name "$PLUGIN_NAME")
  fi

  python3 "${installer_args[@]}"
}

ensure_installed_workspace() {
  ensure_workspace_arg
  if workspace_has_install "$WORKSPACE"; then
    return 0
  fi

  install_workspace
}

doctor() {
  require_tool python3

  printf 'Skill dir: %s\n' "$SKILL_DIR"
  printf 'Template dir: %s\n' "$TEMPLATE_DIR"
  printf 'Default install target: %s\n' "$DEFAULT_WORKSPACE"
  printf 'python3: %s\n' "$(command -v python3 || echo missing)"
  printf 'open: %s\n' "$(command -v open || echo missing)"
  printf 'nmap: %s\n' "$(command -v nmap || echo missing)"
  printf 'Installer: '
  if [[ -x "$INSTALLER" || -f "$INSTALLER" ]]; then
    printf 'present\n'
  else
    printf 'missing\n'
  fi

  printf 'Template files:\n'
  for relative in \
    network-watch.sh \
    .swiftbar-support/open-network-studio.sh \
    .swiftbar-support/refresh-network-studio.sh \
    .swiftbar-support/render-dashboard.py \
    .swiftbar-support/render-swiftbar-menu.py \
    swiftbar/network-monitor.1m.sh
  do
    if [[ -f "$TEMPLATE_DIR/$relative" ]]; then
      printf '  yes  %s\n' "$relative"
    else
      printf '  no   %s\n' "$relative"
    fi
  done

  printf 'Installed workspace: '
  if WORKSPACE="$(find_installed_workspace 2>/dev/null)"; then
    printf '%s\n' "$WORKSPACE"
    printf 'Installed files:\n'
    for relative in \
      network-watch.sh \
      .swiftbar-support/open-network-studio.sh \
      .swiftbar-support/refresh-network-studio.sh \
      logs/network-dashboard.html
    do
      if [[ -f "$WORKSPACE/$relative" ]]; then
        printf '  yes  %s\n' "$relative"
      else
        printf '  no   %s\n' "$relative"
      fi
    done
  else
    printf 'not installed yet\n'
  fi
}

inspect_workspace() {
  resolve_workspace

  cat <<EOF
Workspace target: $WORKSPACE
Template files:
- $TEMPLATE_DIR/network-watch.sh
- $TEMPLATE_DIR/.swiftbar-support/open-network-studio.sh
- $TEMPLATE_DIR/.swiftbar-support/refresh-network-studio.sh
- $TEMPLATE_DIR/.swiftbar-support/render-dashboard.py
- $TEMPLATE_DIR/.swiftbar-support/render-swiftbar-menu.py
- $TEMPLATE_DIR/swiftbar/network-monitor.1m.sh
- $INSTALLER
EOF

  if workspace_has_install "$WORKSPACE"; then
    cat <<EOF
Installed files:
- $WORKSPACE/network-watch.sh
- $WORKSPACE/.swiftbar-support/open-network-studio.sh
- $WORKSPACE/.swiftbar-support/refresh-network-studio.sh
- $WORKSPACE/logs/network-dashboard.html
- $WORKSPACE/swiftbar/network-monitor.1m.sh
EOF
  else
    printf 'Installed workspace: not found yet\n'
  fi
}

refresh_workspace() {
  ensure_installed_workspace
  bash "$WORKSPACE/.swiftbar-support/refresh-network-studio.sh" "$@"
}

open_dashboard() {
  ensure_installed_workspace
  bash "$WORKSPACE/.swiftbar-support/open-network-studio.sh"
}

watch_workspace() {
  ensure_installed_workspace
  (
    cd "$WORKSPACE" &&
    bash "$WORKSPACE/network-watch.sh" "$@"
  )
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --workspace)
      [[ $# -ge 2 ]] || die "--workspace requires a path"
      WORKSPACE="$2"
      shift 2
      ;;
    --swiftbar-plugins-dir)
      [[ $# -ge 2 ]] || die "--swiftbar-plugins-dir requires a path"
      SWIFTBAR_PLUGINS_DIR="$2"
      shift 2
      ;;
    --plugin-name)
      [[ $# -ge 2 ]] || die "--plugin-name requires a value"
      PLUGIN_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    doctor|inspect|install|refresh|open|watch)
      COMMAND="$1"
      shift
      break
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

COMMAND_ARGS=("$@")

if [[ -z "$COMMAND" ]]; then
  usage
  exit 1
fi

if [[ "$COMMAND" == "install" && -z "$WORKSPACE" && ${#COMMAND_ARGS[@]} -gt 0 && "${COMMAND_ARGS[0]}" != -* ]]; then
  WORKSPACE="${COMMAND_ARGS[0]}"
  COMMAND_ARGS=("${COMMAND_ARGS[@]:1}")
fi

case "$COMMAND" in
  doctor)
    doctor
    ;;
  inspect)
    inspect_workspace
    ;;
  install)
    install_workspace
    ;;
  refresh)
    refresh_workspace "${COMMAND_ARGS[@]}"
    ;;
  open)
    open_dashboard
    ;;
  watch)
    watch_workspace "${COMMAND_ARGS[@]}"
    ;;
  *)
    die "Unknown command: $COMMAND"
    ;;
esac
