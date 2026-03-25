#!/usr/bin/env python3
"""Connect gain-tracker to GitHub and manage tracked repositories."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from tracker_config import (
    config_path,
    default_author_pattern,
    detect_github_identity,
    discover_git_repos,
    is_git_repo,
    load_config,
    merge_tracked_repo,
    repo_entry_from_path,
    save_config,
    tracked_repo_entries,
    untrack_repo,
)


def status_payload(config: dict[str, object]) -> dict[str, object]:
    github = config.get("github", {}) if isinstance(config.get("github"), dict) else {}
    repos = tracked_repo_entries(config)
    author_repo = repos[0] if len(repos) == 1 else None
    return {
        "config_path": str(config_path()),
        "connected": bool(github.get("login")),
        "github": github,
        "tracked_repo_count": len(repos),
        "tracked_repos": repos,
        "default_author_pattern": default_author_pattern(config, author_repo),
    }


def render_status(payload: dict[str, object]) -> str:
    lines = [
        f"Config: {payload['config_path']}",
        f"Connected: {'yes' if payload['connected'] else 'no'}",
    ]
    github = payload["github"]
    if github:
        lines.extend(
            [
                f"GitHub login: {github.get('login', '')}",
                f"GitHub name: {github.get('name', '')}",
                f"Git user name: {github.get('git_user_name', '')}",
                f"Git user email: {github.get('git_user_email', '')}",
            ]
        )

    lines.append(f"Tracked repos: {payload['tracked_repo_count']}")
    for repo in payload["tracked_repos"]:
        label = repo.get("full_name") or repo.get("label") or repo.get("path")
        lines.append(f"- {label}: {repo.get('path', '')}")

    author_pattern = payload.get("default_author_pattern")
    if author_pattern:
        lines.append(f"Default author filter: {author_pattern}")
    return "\n".join(lines)


def track_paths(config: dict[str, object], paths: list[Path]) -> tuple[list[dict[str, object]], list[dict[str, str]]]:
    tracked: list[dict[str, object]] = []
    skipped: list[dict[str, str]] = []
    seen: set[str] = set()

    for path in paths:
        resolved = path.expanduser().resolve()
        key = str(resolved)
        if key in seen:
            continue
        seen.add(key)
        try:
            tracked.append(merge_tracked_repo(config, repo_entry_from_path(resolved)))
        except RuntimeError as exc:
            skipped.append(
                {
                    "path": key,
                    "reason": str(exc),
                }
            )

    return tracked, skipped


def connect_command(repo_paths: list[str], track_cwd: bool, as_json: bool) -> int:
    config = load_config()
    config["github"] = detect_github_identity()

    paths = [Path(path).expanduser() for path in repo_paths]
    if track_cwd and is_git_repo(Path.cwd()):
        paths.append(Path.cwd())

    tracked, skipped = track_paths(config, paths)
    save_config(config)
    payload = status_payload(config)
    payload["tracked_now"] = tracked
    payload["skipped"] = skipped
    if as_json:
        json.dump(payload, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0

    sys.stdout.write(render_status(payload))
    sys.stdout.write("\n")
    if tracked:
        sys.stdout.write("Tracked this run:\n")
        for repo in tracked:
            sys.stdout.write(f"- {repo.get('full_name', repo.get('path', ''))}\n")
    if skipped:
        sys.stdout.write("Skipped this run:\n")
        for skipped_repo in skipped:
            sys.stdout.write(f"- {skipped_repo['path']}: {skipped_repo['reason']}\n")
    return 0


def track_repo_command(repo_path: str, as_json: bool) -> int:
    config = load_config()
    repo_entry = merge_tracked_repo(config, repo_entry_from_path(Path(repo_path)))
    save_config(config)
    payload = {
        "config_path": str(config_path()),
        "tracked_repo": repo_entry,
        "tracked_repo_count": len(tracked_repo_entries(config)),
    }
    if as_json:
        json.dump(payload, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0
    sys.stdout.write(f"Tracked {repo_entry.get('full_name', repo_entry.get('path', ''))}\n")
    sys.stdout.write(f"Config: {config_path()}\n")
    return 0


def untrack_repo_command(repo_path: str, as_json: bool) -> int:
    config = load_config()
    removed = untrack_repo(config, repo_path)
    save_config(config)
    payload = {
        "config_path": str(config_path()),
        "removed": removed,
        "tracked_repo_count": len(tracked_repo_entries(config)),
    }
    if as_json:
        json.dump(payload, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0
    sys.stdout.write(f"Removed {removed} tracked repo entry\n")
    sys.stdout.write(f"Config: {config_path()}\n")
    return 0


def track_dir_command(dir_path: str, max_depth: int, as_json: bool) -> int:
    config = load_config()
    root = Path(dir_path).expanduser()
    discovered = discover_git_repos(root, max_depth=max_depth)
    tracked, skipped = track_paths(config, discovered)
    save_config(config)

    payload = {
        "config_path": str(config_path()),
        "root": str(root.resolve()),
        "max_depth": max_depth,
        "discovered_repo_count": len(discovered),
        "tracked_now_count": len(tracked),
        "tracked_now": tracked,
        "skipped": skipped,
        "tracked_repo_count": len(tracked_repo_entries(config)),
    }
    if as_json:
        json.dump(payload, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0

    sys.stdout.write(f"Scanned {payload['root']}\n")
    sys.stdout.write(f"Discovered git repos: {payload['discovered_repo_count']}\n")
    sys.stdout.write(f"Tracked this run: {payload['tracked_now_count']}\n")
    if tracked:
        for repo in tracked:
            sys.stdout.write(f"- {repo.get('full_name', repo.get('path', ''))}\n")
    if skipped:
        sys.stdout.write("Skipped:\n")
        for skipped_repo in skipped:
            sys.stdout.write(f"- {skipped_repo['path']}: {skipped_repo['reason']}\n")
    if not tracked and not skipped:
        sys.stdout.write("No git repositories found in that directory.\n")
    sys.stdout.write(f"Config: {config_path()}\n")
    return 0


def status_command(as_json: bool) -> int:
    payload = status_payload(load_config())
    if as_json:
        json.dump(payload, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0
    sys.stdout.write(render_status(payload))
    sys.stdout.write("\n")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Connect gain-tracker to GitHub and manage tracked repos.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    connect_parser = subparsers.add_parser("connect", help="Connect using gh auth and optionally track repos")
    connect_parser.add_argument("--repo", action="append", default=[], help="Repo path to track after connecting")
    connect_parser.add_argument("--track-cwd", action="store_true", help="Track the current working directory if it is a git repo")

    track_parser = subparsers.add_parser("track-repo", help="Add a tracked repository")
    track_parser.add_argument("--repo", required=True, help="Repo path to track")

    track_dir_parser = subparsers.add_parser("track-dir", help="Scan a directory and track GitHub repos found inside it")
    track_dir_parser.add_argument("--dir", required=True, help="Directory to scan for git repositories")
    track_dir_parser.add_argument("--max-depth", type=int, default=3, help="Maximum directory depth to scan")

    untrack_parser = subparsers.add_parser("untrack-repo", help="Remove a tracked repository")
    untrack_parser.add_argument("--repo", required=True, help="Repo path to untrack")

    subparsers.add_parser("status", help="Show current GitHub and repo tracking status")
    subparsers.add_parser("list-repos", help="List tracked repositories")

    argv = list(sys.argv[1:])
    json_output = False
    if "--json" in argv:
        json_output = True
        argv = [arg for arg in argv if arg != "--json"]

    args = parser.parse_args(argv)
    args.json = json_output

    try:
        if args.command == "connect":
            return connect_command(args.repo, args.track_cwd, args.json)
        if args.command == "track-repo":
            return track_repo_command(args.repo, args.json)
        if args.command == "track-dir":
            return track_dir_command(args.dir, args.max_depth, args.json)
        if args.command == "untrack-repo":
            return untrack_repo_command(args.repo, args.json)
        if args.command == "status":
            return status_command(args.json)
        if args.command == "list-repos":
            return status_command(args.json)
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
