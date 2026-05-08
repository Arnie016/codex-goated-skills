#!/usr/bin/env bash
set -euo pipefail

INSTALL_DIR="${INSTALL_DIR:-$HOME/.local/bin}"
COMMAND_NAME="${COMMAND_NAME:-iconbar}"
TARGET="$INSTALL_DIR/$COMMAND_NAME"
RAW_URL="${RAW_URL:-https://raw.githubusercontent.com/Arnie016/codex-goated-skills/main/bin/codex-goated}"
REPO_DIR=""

usage() {
  cat <<'EOF'
Usage:
  install-cli.sh [--install-dir PATH] [--repo-dir PATH] [--command-name NAME]

Examples:
  sh install-cli.sh
  sh install-cli.sh --install-dir ~/.local/bin
  sh install-cli.sh --repo-dir /path/to/codex-goated-skills
  sh install-cli.sh --command-name iconbar
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

require_fetch() {
  command -v curl >/dev/null 2>&1 || die "curl is required."
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      [[ $# -ge 2 ]] || die "--install-dir requires a path"
      INSTALL_DIR="$2"
      TARGET="$INSTALL_DIR/$COMMAND_NAME"
      shift 2
      ;;
    --repo-dir)
      [[ $# -ge 2 ]] || die "--repo-dir requires a path"
      REPO_DIR="$2"
      shift 2
      ;;
    --command-name)
      [[ $# -ge 2 ]] || die "--command-name requires a name"
      COMMAND_NAME="$2"
      TARGET="$INSTALL_DIR/$COMMAND_NAME"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "Unknown argument: $1"
      ;;
  esac
done

mkdir -p "$INSTALL_DIR"
case "$COMMAND_NAME" in
  ""|"."|".."|*/*|*\\*)
    die "Invalid command name: $COMMAND_NAME"
    ;;
esac

if [[ -n "$REPO_DIR" ]]; then
  [[ -f "$REPO_DIR/bin/codex-goated" ]] || die "Missing CLI at $REPO_DIR/bin/codex-goated"
  REPO_DIR_ABS="$(cd "$REPO_DIR" && pwd)"
  cat > "$TARGET" <<EOF
#!/usr/bin/env bash
export ICONBAR_REPO_DIR="$REPO_DIR_ABS"
exec "$REPO_DIR_ABS/bin/codex-goated" "\$@"
EOF
else
  require_fetch
  curl -fsSL "$RAW_URL" -o "$TARGET"
fi

chmod +x "$TARGET"

printf 'Installed %s to %s\n' "$COMMAND_NAME" "$TARGET"

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    ;;
  *)
    printf 'Add %s to your PATH to use the command everywhere.\n' "$INSTALL_DIR"
    ;;
esac

printf 'Try:\n'
printf '  %s list\n' "$COMMAND_NAME"
printf '  %s search workflow\n' "$COMMAND_NAME"
printf '  %s pack list\n' "$COMMAND_NAME"
printf '  %s security\n' "$COMMAND_NAME"
printf '  %s press --output dist\n' "$COMMAND_NAME"
