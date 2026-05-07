#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PLUGIN_SOURCE="$SCRIPT_DIR/security-sentry-bar.1m.sh"
PLUGIN_NAME="security-sentry-bar.1m.sh"
SWIFTBAR_PLUGINS_DIR="${SWIFTBAR_PLUGINS_DIR:-$HOME/SwiftBarPlugins}"
COMMAND="${1:-}"

usage() {
  cat <<'EOF'
Usage:
  run_security_sentry_bar.sh <command>

Commands:
  doctor       Check local tools and SwiftBar plugin folder
  inspect      Print important files and install target
  install      Copy the SwiftBar plugin into the plugin folder
  preview      Render one SwiftBar menu snapshot in the terminal
  full-scan    Run the full terminal summary
  test         Run shell syntax checks and a short preview smoke test

Environment:
  SWIFTBAR_PLUGINS_DIR=/path/to/plugins
  SECURITY_SENTRY_SUSPICIOUS_CIDRS="203.0.113.0/24"
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

have_tool() {
  command -v "$1" >/dev/null 2>&1
}

doctor() {
  printf 'Skill dir: %s\n' "$SKILL_DIR"
  printf 'Plugin source: %s\n' "$PLUGIN_SOURCE"
  printf 'Plugin target dir: %s\n' "$SWIFTBAR_PLUGINS_DIR"
  printf 'bash: %s\n' "$(command -v bash || echo missing)"
  printf 'lsof: %s\n' "$(command -v lsof || echo missing)"
  printf 'ps: %s\n' "$(command -v ps || echo missing)"
  printf 'find: %s\n' "$(command -v find || echo missing)"
  printf 'dscacheutil: %s\n' "$(command -v dscacheutil || echo missing)"
  printf 'SwiftBar app: '
  if [[ -d "/Applications/SwiftBar.app" || -d "$HOME/Applications/SwiftBar.app" ]]; then
    printf 'present\n'
  else
    printf 'not found in Applications; plugin still works with SwiftBar/XBar once installed\n'
  fi
  printf 'Plugin folder: '
  if [[ -d "$SWIFTBAR_PLUGINS_DIR" ]]; then
    printf 'present\n'
  else
    printf 'missing, install will create it\n'
  fi
}

inspect() {
  cat <<EOF
Security Sentry Bar files:
- $SKILL_DIR/SKILL.md
- $SKILL_DIR/manifest.json
- $SKILL_DIR/agents/openai.yaml
- $PLUGIN_SOURCE
- $SKILL_DIR/references/security-sentry-map.md
- $SKILL_DIR/assets/security-sentry-bar-small.svg
- $SKILL_DIR/assets/security-sentry-bar-large.svg
- $SKILL_DIR/prototype/SkillMenuBarApp.swift
- $SKILL_DIR/prototype/SkillMenuBarView.swift
- $SKILL_DIR/prototype/SkillDetailView.swift
- $SKILL_DIR/prototype/SkillTheme.swift

SwiftBar target:
- $SWIFTBAR_PLUGINS_DIR/$PLUGIN_NAME
EOF
}

install_plugin() {
  [[ -f "$PLUGIN_SOURCE" ]] || die "Missing plugin source: $PLUGIN_SOURCE"
  mkdir -p "$SWIFTBAR_PLUGINS_DIR"
  cp "$PLUGIN_SOURCE" "$SWIFTBAR_PLUGINS_DIR/$PLUGIN_NAME"
  chmod +x "$SWIFTBAR_PLUGINS_DIR/$PLUGIN_NAME"
  printf 'Installed SwiftBar plugin: %s\n' "$SWIFTBAR_PLUGINS_DIR/$PLUGIN_NAME"
}

test_plugin() {
  bash -n "$PLUGIN_SOURCE"
  bash -n "$0"
  local preview_file
  preview_file="$(mktemp)"
  bash "$PLUGIN_SOURCE" menu > "$preview_file"
  head -n 8 "$preview_file" >/dev/null
  rm -f "$preview_file"
  printf 'Security Sentry Bar shell checks passed.\n'
}

case "$COMMAND" in
  doctor)
    doctor
    ;;
  inspect)
    inspect
    ;;
  install)
    install_plugin
    ;;
  preview)
    bash "$PLUGIN_SOURCE" menu
    ;;
  full-scan)
    bash "$PLUGIN_SOURCE" full-scan
    ;;
  test)
    test_plugin
    ;;
  -h|--help|"")
    usage
    ;;
  *)
    die "Unknown command: $COMMAND"
    ;;
esac
