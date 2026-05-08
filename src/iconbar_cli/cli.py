from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path


DEFAULT_REPO_URL = "https://github.com/Arnie016/codex-goated-skills.git"


def _data_home() -> Path:
    if os.environ.get("XDG_DATA_HOME"):
        return Path(os.environ["XDG_DATA_HOME"]).expanduser()
    if sys.platform == "darwin":
        return Path.home() / "Library" / "Application Support"
    return Path.home() / ".local" / "share"


def _repo_cache_dir() -> Path:
    return Path(os.environ.get("ICONBAR_CACHE_DIR", _data_home() / "iconbar")) / "repo"


def _is_repo_dir(path: Path) -> bool:
    return (path / "bin" / "codex-goated").is_file() and (path / "skills").is_dir()


def _repo_url() -> str:
    url = os.environ.get("ICONBAR_REPO_URL", DEFAULT_REPO_URL)
    if not url.startswith("https://"):
        raise SystemExit("Error: ICONBAR_REPO_URL must use HTTPS. Use ICONBAR_REPO_DIR for local clones.")
    return url


def _clone_repo(target: Path) -> None:
    if shutil.which("git") is None:
        raise SystemExit("Error: git is required for first-run Iconbar setup.")

    target.parent.mkdir(parents=True, exist_ok=True)
    url = _repo_url()
    print(f"Fetching Iconbar catalog from {url}", file=sys.stderr)
    subprocess.run(
        ["git", "clone", "--depth", "1", url, str(target)],
        check=True,
    )


def _ensure_repo() -> Path:
    env_repo = os.environ.get("ICONBAR_REPO_DIR") or os.environ.get("CODEX_GOATED_REPO_DIR")
    if env_repo:
        repo = Path(env_repo).expanduser().resolve()
        if not _is_repo_dir(repo):
            raise SystemExit(f"Error: ICONBAR_REPO_DIR is not an Iconbar repo: {repo}")
        return repo

    repo = _repo_cache_dir().expanduser()
    if _is_repo_dir(repo):
        return repo

    if repo.exists():
        raise SystemExit(
            f"Error: Iconbar cache exists but is incomplete: {repo}\n"
            "Remove it or set ICONBAR_REPO_DIR to a local checkout."
        )

    _clone_repo(repo)
    if not _is_repo_dir(repo):
        raise SystemExit(f"Error: cloned Iconbar repo is incomplete: {repo}")
    return repo


def main(argv: list[str] | None = None) -> int:
    args = list(sys.argv[1:] if argv is None else argv)
    repo = _ensure_repo()
    command = repo / "bin" / "codex-goated"
    env = os.environ.copy()
    env["ICONBAR_REPO_DIR"] = str(repo)
    os.execvpe(str(command), ["iconbar", *args], env)
    return 127
