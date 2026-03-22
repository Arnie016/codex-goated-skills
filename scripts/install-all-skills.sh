#!/usr/bin/env bash
set -euo pipefail

DEST="${CODEX_HOME:-$HOME/.codex}/skills"
REPO_DIR=""
REPO_URL="https://github.com/Arnie016/codex-goated-skills.git"
OVERWRITE=0
TEMP_DIR=""

usage() {
  cat <<'EOF'
Usage:
  install-all-skills.sh [--dest PATH] [--repo-dir PATH] [--repo-url URL] [--overwrite]

Examples:
  bash install-all-skills.sh
  bash install-all-skills.sh --dest ~/.codex/skills --overwrite
  bash install-all-skills.sh --repo-dir /path/to/codex-goated-skills
EOF
}

die() {
  printf 'Error: %s\n' "$*" >&2
  exit 1
}

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

require_tools() {
  command -v git >/dev/null 2>&1 || die "git is required."
}

clone_repo() {
  require_tools
  TEMP_DIR="$(mktemp -d)"
  trap cleanup EXIT
  git clone --depth 1 "$REPO_URL" "$TEMP_DIR/repo" >/dev/null 2>&1 || die "Failed to clone $REPO_URL"
  REPO_DIR="$TEMP_DIR/repo"
}

install_skills() {
  local skills_dir target skill_dir skill_name

  skills_dir="$REPO_DIR/skills"
  [[ -d "$skills_dir" ]] || die "No skills directory found in $REPO_DIR"

  mkdir -p "$DEST"

  printf 'Installing skills into: %s\n' "$DEST"

  for skill_dir in "$skills_dir"/*; do
    [[ -d "$skill_dir" ]] || continue
    skill_name="$(basename "$skill_dir")"
    target="$DEST/$skill_name"

    if [[ -e "$target" ]]; then
      if [[ "$OVERWRITE" -eq 1 ]]; then
        rm -rf "$target"
      else
        printf 'Skipped %s (already installed)\n' "$skill_name"
        continue
      fi
    fi

    cp -R "$skill_dir" "$target"
    printf 'Installed %s\n' "$skill_name"
  done

  printf 'Restart Codex to pick up new skills.\n'
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dest)
      [[ $# -ge 2 ]] || die "--dest requires a path"
      DEST="$2"
      shift 2
      ;;
    --repo-dir)
      [[ $# -ge 2 ]] || die "--repo-dir requires a path"
      REPO_DIR="$2"
      shift 2
      ;;
    --repo-url)
      [[ $# -ge 2 ]] || die "--repo-url requires a url"
      REPO_URL="$2"
      shift 2
      ;;
    --overwrite)
      OVERWRITE=1
      shift
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

if [[ -z "$REPO_DIR" ]]; then
  clone_repo
fi

install_skills
