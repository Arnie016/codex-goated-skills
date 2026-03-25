#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_URL="${REPO_URL:-https://github.com/Arnie016/codex-goated-skills.git}"
TEMP_DIR=""
SELECTED_REPO_ROOT=""

usage() {
  cat <<'EOF'
Usage:
  install-fandom-pack.sh [install-skill.sh options]

Examples:
  bash scripts/install-fandom-pack.sh
  bash scripts/install-fandom-pack.sh --dest "$HOME/.codex/skills"
  bash scripts/install-fandom-pack.sh --repo-dir /path/to/codex-goated-skills --overwrite
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

repo_dir_from_args() {
  local previous=""
  for arg in "$@"; do
    if [[ "$previous" == "--repo-dir" ]]; then
      printf '%s\n' "$arg"
      return 0
    fi
    previous="$arg"
  done
  return 1
}

has_repo_dir_arg() {
  local arg
  for arg in "$@"; do
    [[ "$arg" == "--repo-dir" ]] && return 0
  done
  return 1
}

resolve_repo_root() {
  local explicit_root=""
  explicit_root="$(repo_dir_from_args "$@" || true)"
  if [[ -n "$explicit_root" ]]; then
    [[ -f "$explicit_root/collections/fandom-skill-pack.txt" && -f "$explicit_root/scripts/install-skill.sh" ]] || {
      printf 'Error: --repo-dir does not point to a codex-goated-skills checkout with the fandom pack.\n' >&2
      exit 1
    }
    SELECTED_REPO_ROOT="$explicit_root"
    return 0
  fi

  if [[ -f "$REPO_ROOT/collections/fandom-skill-pack.txt" && -f "$REPO_ROOT/scripts/install-skill.sh" ]]; then
    SELECTED_REPO_ROOT="$REPO_ROOT"
    return 0
  fi

  command -v git >/dev/null 2>&1 || {
    printf 'Error: git is required when install-fandom-pack.sh is run outside a local repo clone.\n' >&2
    exit 1
  }

  TEMP_DIR="$(mktemp -d)"
  trap cleanup EXIT
  git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo" >/dev/null 2>&1 || {
    printf 'Error: failed to clone %s\n' "$REPO_URL" >&2
    exit 1
  }
  SELECTED_REPO_ROOT="$TEMP_DIR/repo"
}

resolve_repo_root "$@"
PACK_FILE="$SELECTED_REPO_ROOT/collections/fandom-skill-pack.txt"
INSTALL_SCRIPT="$SELECTED_REPO_ROOT/scripts/install-skill.sh"

mapfile -t SKILLS < <(grep -v '^[[:space:]]*$' "$PACK_FILE" | grep -v '^[[:space:]]*#')

[[ ${#SKILLS[@]} -gt 0 ]] || {
  printf 'Error: no skills listed in %s\n' "$PACK_FILE" >&2
  exit 1
}

if has_repo_dir_arg "$@"; then
  bash "$INSTALL_SCRIPT" "$@" "${SKILLS[@]}"
else
  bash "$INSTALL_SCRIPT" --repo-dir "$SELECTED_REPO_ROOT" "$@" "${SKILLS[@]}"
fi
