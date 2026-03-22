#!/usr/bin/env bash
set -euo pipefail

DEST="${CODEX_HOME:-$HOME/.codex}/skills"
REPO_DIR=""
REPO_URL="https://github.com/Arnie016/codex-goated-skills.git"
OVERWRITE=0
LIST_ONLY=0
TEMP_DIR=""
SKILL_NAMES=()

usage() {
  cat <<'EOF'
Usage:
  install-skill.sh [--dest PATH] [--repo-dir PATH] [--repo-url URL] [--overwrite] [--list] <skill-name> [<skill-name> ...]

Examples:
  bash install-skill.sh network-studio
  bash install-skill.sh vibe-bluetooth
  bash install-skill.sh --list
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

list_skills() {
  local skills_dir skill_dir
  skills_dir="$REPO_DIR/skills"
  [[ -d "$skills_dir" ]] || die "No skills directory found in $REPO_DIR"

  for skill_dir in "$skills_dir"/*; do
    [[ -d "$skill_dir" ]] || continue
    basename "$skill_dir"
  done
}

install_skill() {
  local skill_name="$1"
  local skills_dir source target

  skills_dir="$REPO_DIR/skills"
  source="$skills_dir/$skill_name"
  target="$DEST/$skill_name"

  [[ -d "$source" ]] || die "Unknown skill: $skill_name"
  mkdir -p "$DEST"

  if [[ -e "$target" ]]; then
    if [[ "$OVERWRITE" -eq 1 ]]; then
      rm -rf "$target"
    else
      printf 'Skipped %s (already installed)\n' "$skill_name"
      return 0
    fi
  fi

  cp -R "$source" "$target"
  printf 'Installed %s\n' "$skill_name"
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
    --list)
      LIST_ONLY=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      SKILL_NAMES+=("$1")
      shift
      ;;
  esac
done

if [[ -z "$REPO_DIR" ]]; then
  clone_repo
fi

if [[ "$LIST_ONLY" -eq 1 ]]; then
  list_skills
  exit 0
fi

[[ ${#SKILL_NAMES[@]} -gt 0 ]] || die "Pass at least one skill name or use --list"

for skill_name in "${SKILL_NAMES[@]}"; do
  install_skill "$skill_name"
done

printf 'Restart Codex to pick up new skills.\n'
