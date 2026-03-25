#!/usr/bin/env python3
"""Shared config helpers for the gain-tracker skill."""

from __future__ import annotations

import json
import os
import re
import shutil
import subprocess
from datetime import datetime, timezone
from pathlib import Path


def now_iso() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")


def codex_home() -> Path:
    return Path(os.environ.get("CODEX_HOME", Path.home() / ".codex")).expanduser()


def tracker_dir() -> Path:
    return codex_home() / "gain-tracker"


def config_path() -> Path:
    return tracker_dir() / "config.json"


def default_config() -> dict[str, object]:
    return {
        "github": {},
        "tracked_repos": [],
    }


def load_config() -> dict[str, object]:
    path = config_path()
    if not path.is_file():
        return default_config()

    data = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(data.get("github"), dict):
        data["github"] = {}
    if not isinstance(data.get("tracked_repos"), list):
        data["tracked_repos"] = []
    return data


def save_config(config: dict[str, object]) -> Path:
    path = config_path()
    path.parent.mkdir(parents=True, exist_ok=True)
    config["updated_at"] = now_iso()
    path.write_text(json.dumps(config, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    return path


def run_command(cmd: list[str]) -> str:
    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        stderr = result.stderr.strip() or "command failed"
        raise RuntimeError(stderr)
    return result.stdout.strip()


def command_exists(name: str) -> bool:
    return shutil.which(name) is not None


def gh_api_json(endpoint: str) -> dict[str, object]:
    if not command_exists("gh"):
        raise RuntimeError("gh is not installed")
    return json.loads(run_command(["gh", "api", endpoint]))


def safe_git_config(key: str, repo: Path | None = None, global_scope: bool = False) -> str:
    try:
        if repo is not None:
            return run_command(["git", "-C", str(repo), "config", key])
        if global_scope:
            return run_command(["git", "config", "--global", key])
        return run_command(["git", "config", key])
    except RuntimeError:
        return ""


def is_git_repo(path: Path) -> bool:
    try:
        result = run_command(["git", "-C", str(path), "rev-parse", "--is-inside-work-tree"])
        return result == "true"
    except RuntimeError:
        return False


def parse_github_remote(url: str) -> dict[str, str] | None:
    patterns = [
        r"^https://github\.com/(?P<owner>[^/]+)/(?P<repo>[^/]+?)(?:\.git)?$",
        r"^git@github\.com:(?P<owner>[^/]+)/(?P<repo>[^/]+?)(?:\.git)?$",
        r"^ssh://git@github\.com/(?P<owner>[^/]+)/(?P<repo>[^/]+?)(?:\.git)?$",
        r"^git://github\.com/(?P<owner>[^/]+)/(?P<repo>[^/]+?)(?:\.git)?$",
    ]
    for pattern in patterns:
        match = re.match(pattern, url)
        if match:
            owner = match.group("owner")
            repo = match.group("repo")
            return {
                "owner": owner,
                "name": repo,
                "full_name": f"{owner}/{repo}",
            }
    return None


def detect_github_identity() -> dict[str, str]:
    data = gh_api_json("user")
    login = str(data.get("login", ""))
    name = str(data.get("name") or login)
    return {
        "login": login,
        "name": name,
        "html_url": str(data.get("html_url", "")),
        "avatar_url": str(data.get("avatar_url", "")),
        "public_repos": str(data.get("public_repos", "")),
        "git_user_name": safe_git_config("user.name", global_scope=True),
        "git_user_email": safe_git_config("user.email", global_scope=True),
        "connected_via": "gh",
        "connected_at": now_iso(),
    }


def repo_entry_from_path(repo_path: Path) -> dict[str, object]:
    resolved = repo_path.expanduser().resolve()
    if not is_git_repo(resolved):
        raise RuntimeError(f"not a git repository: {resolved}")

    remote_url = run_command(["git", "-C", str(resolved), "remote", "get-url", "origin"])
    remote = parse_github_remote(remote_url)
    if remote is None:
        raise RuntimeError(f"origin is not a GitHub remote: {remote_url}")

    entry: dict[str, object] = {
        "path": str(resolved),
        "label": resolved.name,
        "owner": remote["owner"],
        "name": remote["name"],
        "full_name": remote["full_name"],
        "html_url": f"https://github.com/{remote['full_name']}",
        "default_branch": "",
        "private": False,
        "last_seen_remote": remote_url,
        "git_user_name": safe_git_config("user.name", repo=resolved) or safe_git_config("user.name", global_scope=True),
        "git_user_email": safe_git_config("user.email", repo=resolved) or safe_git_config("user.email", global_scope=True),
        "added_at": now_iso(),
        "updated_at": now_iso(),
    }

    try:
        repo_data = gh_api_json(f"repos/{remote['full_name']}")
        entry["label"] = str(repo_data.get("name", resolved.name))
        entry["html_url"] = str(repo_data.get("html_url", entry["html_url"]))
        entry["default_branch"] = str(repo_data.get("default_branch", ""))
        entry["private"] = bool(repo_data.get("private", False))
    except RuntimeError:
        pass

    return entry


def merge_tracked_repo(config: dict[str, object], entry: dict[str, object]) -> dict[str, object]:
    repos = list(config.get("tracked_repos", []))
    path_value = str(entry.get("path", ""))
    full_name = str(entry.get("full_name", ""))

    for index, existing in enumerate(repos):
        if not isinstance(existing, dict):
            continue
        if str(existing.get("path", "")) == path_value or (full_name and str(existing.get("full_name", "")) == full_name):
            added_at = existing.get("added_at") or entry.get("added_at") or now_iso()
            merged = dict(existing)
            merged.update(entry)
            merged["added_at"] = added_at
            merged["updated_at"] = now_iso()
            repos[index] = merged
            config["tracked_repos"] = repos
            return merged

    entry = dict(entry)
    entry["added_at"] = entry.get("added_at") or now_iso()
    entry["updated_at"] = now_iso()
    repos.append(entry)
    config["tracked_repos"] = repos
    return entry


def untrack_repo(config: dict[str, object], repo_path: str) -> int:
    resolved = str(Path(repo_path).expanduser().resolve())
    repos = [repo for repo in config.get("tracked_repos", []) if str(repo.get("path", "")) != resolved]
    removed = len(config.get("tracked_repos", [])) - len(repos)
    config["tracked_repos"] = repos
    return removed


def tracked_repo_entries(config: dict[str, object]) -> list[dict[str, object]]:
    repos: list[dict[str, object]] = []
    for repo in config.get("tracked_repos", []):
        if not isinstance(repo, dict):
            continue
        path_value = repo.get("path")
        if not path_value:
            continue
        path = Path(str(path_value)).expanduser()
        if path.exists() and is_git_repo(path):
            repos.append(repo)
    return repos


def default_author_pattern(config: dict[str, object], repo_entry: dict[str, object] | None = None) -> str | None:
    github = config.get("github", {}) if isinstance(config.get("github"), dict) else {}
    repo_entry = repo_entry or {}
    candidates = [
        repo_entry.get("git_user_email"),
        github.get("git_user_email"),
        repo_entry.get("git_user_name"),
        github.get("git_user_name"),
        github.get("name"),
        github.get("login"),
    ]
    cleaned: list[str] = []
    for candidate in candidates:
        value = str(candidate or "").strip()
        if value and value not in cleaned:
            cleaned.append(value)
    if not cleaned:
        return None
    return r"\|".join(re.escape(value) for value in cleaned)
