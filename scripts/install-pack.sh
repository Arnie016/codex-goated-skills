#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
REPO_URL="${REPO_URL:-https://github.com/Arnie016/codex-goated-skills.git}"
TEMP_DIR=""
SELECTED_REPO_ROOT=""
PACK_NAME=""
FORWARDED_ARGS=()

usage() {
  cat <<'EOF'
Usage:
  install-pack.sh [install-skill.sh options] <pack-name>

Examples:
  bash scripts/install-pack.sh fandom-skill-pack
  bash scripts/install-pack.sh creator-and-fandom-stack
  bash scripts/install-pack.sh --dest "$HOME/.codex/skills" launch-and-distribution
  bash scripts/install-pack.sh --repo-dir /path/to/codex-goated-skills --overwrite utility-builder-stack
EOF
}

cleanup() {
  if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
    rm -rf "$TEMP_DIR"
  fi
}

repo_dir_from_args() {
  local previous=""
  local arg
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
    [[ -d "$explicit_root/collections" && -f "$explicit_root/scripts/install-skill.sh" ]] || {
      printf 'Error: --repo-dir does not point to a codex-goated-skills checkout with collections support.\n' >&2
      exit 1
    }
    SELECTED_REPO_ROOT="$explicit_root"
    return 0
  fi

  if [[ -d "$REPO_ROOT/collections" && -f "$REPO_ROOT/scripts/install-skill.sh" ]]; then
    SELECTED_REPO_ROOT="$REPO_ROOT"
    return 0
  fi

  command -v git >/dev/null 2>&1 || {
    printf 'Error: git is required when install-pack.sh is run outside a local repo clone.\n' >&2
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

parse_pack_name() {
  local args=("$@")
  local index=0
  while [[ $index -lt ${#args[@]} ]]; do
    case "${args[$index]}" in
      --dest|--repo-dir|--repo-url)
        FORWARDED_ARGS+=("${args[$index]}")
        index=$((index + 2))
        [[ $index -le ${#args[@]} ]] && FORWARDED_ARGS+=("${args[$((index - 1))]}")
        ;;
      --overwrite)
        FORWARDED_ARGS+=("${args[$index]}")
        index=$((index + 1))
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        if [[ -n "$PACK_NAME" ]]; then
          printf 'Error: pass exactly one pack name\n' >&2
          exit 1
        fi
        PACK_NAME="${args[$index]}"
        index=$((index + 1))
        ;;
    esac
  done

  [[ -n "$PACK_NAME" ]] || {
    usage
    exit 1
  }
}

pack_file_path() {
  if [[ "$PACK_NAME" == *.txt ]]; then
    printf '%s\n' "$SELECTED_REPO_ROOT/collections/$PACK_NAME"
  else
    printf '%s\n' "$SELECTED_REPO_ROOT/collections/$PACK_NAME.txt"
  fi
}

parse_pack_skills() {
  local pack_file
  pack_file="$(pack_file_path)"
  [[ -f "$pack_file" ]] || {
    printf 'Error: unknown pack: %s\n' "$PACK_NAME" >&2
    exit 1
  }
  grep -v '^[[:space:]]*$' "$pack_file" | grep -v '^[[:space:]]*#'
}

[[ "${1:-}" == "-h" || "${1:-}" == "--help" ]] && {
  usage
  exit 0
}

parse_pack_name "$@"
resolve_repo_root "$@"

mapfile -t SKILLS < <(parse_pack_skills)

[[ ${#SKILLS[@]} -gt 0 ]] || {
  printf 'Error: no skills listed for pack %s\n' "$PACK_NAME" >&2
  exit 1
}

INSTALL_SCRIPT="$SELECTED_REPO_ROOT/scripts/install-skill.sh"

if has_repo_dir_arg "$@"; then
  bash "$INSTALL_SCRIPT" "${FORWARDED_ARGS[@]}" "${SKILLS[@]}"
else
  bash "$INSTALL_SCRIPT" --repo-dir "$SELECTED_REPO_ROOT" "${FORWARDED_ARGS[@]}" "${SKILLS[@]}"
fi
