#!/usr/bin/env python3
"""Compatibility commands for the local skill market maintenance loop."""

from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def run(command: list[str], label: str | None = None) -> int:
    if label:
        print(f"\n== {label} ==")
        print(" ".join(command), flush=True)
    return subprocess.run(command, check=False).returncode


def capture(command: list[str]) -> tuple[int, str, str]:
    result = subprocess.run(command, check=False, capture_output=True, text=True)
    return result.returncode, result.stdout.strip(), result.stderr.strip()


def git_capture(repo_root: Path, *args: str) -> tuple[int, str, str]:
    return capture(["git", "-C", str(repo_root), *args])


def print_key_value(label: str, value: str) -> None:
    print(f"{label}: {value}")


def sync(repo_root: Path) -> int:
    return run(
        [
            sys.executable,
            str(repo_root / "scripts" / "build-catalog.py"),
            "--repo-dir",
            str(repo_root),
        ]
    )


def audit(repo_root: Path) -> int:
    catalog_status = run(
        [
            sys.executable,
            str(repo_root / "scripts" / "build-catalog.py"),
            "--repo-dir",
            str(repo_root),
            "--check",
        ]
    )
    if catalog_status != 0:
        return catalog_status

    return run([str(repo_root / "bin" / "codex-goated"), "audit", "--repo-dir", str(repo_root)])


def develop(repo_root: Path) -> int:
    """Run the bounded local loop before shipping SkillBar or catalog changes."""

    steps = [
        (
            "Rebuild catalog index",
            [sys.executable, str(repo_root / "scripts" / "build_skill_market_index.py")],
        ),
        (
            "Sync generated catalog",
            [sys.executable, str(repo_root / "scripts" / "skill_market_loop.py"), "sync"],
        ),
        (
            "Audit skill market",
            [sys.executable, str(repo_root / "scripts" / "skill_market_loop.py"), "audit"],
        ),
        (
            "SkillBar doctor",
            ["bash", str(repo_root / "skills" / "skillbar" / "scripts" / "run_skillbar.sh"), "doctor"],
        ),
        (
            "SkillBar typecheck",
            ["bash", str(repo_root / "skills" / "skillbar" / "scripts" / "run_skillbar.sh"), "typecheck"],
        ),
        (
            "SkillBar catalog check",
            ["bash", str(repo_root / "skills" / "skillbar" / "scripts" / "run_skillbar.sh"), "catalog-check"],
        ),
        (
            "SkillBar audit",
            ["bash", str(repo_root / "skills" / "skillbar" / "scripts" / "run_skillbar.sh"), "audit"],
        ),
    ]

    for label, command in steps:
        status = run(command, label)
        if status != 0:
            print(f"\nStopped at: {label}", file=sys.stderr)
            return status

    print("\nDevelopment loop complete.")
    return 0


def publish_check(repo_root: Path, strict: bool = False) -> int:
    """Report whether the current branch is ready for safe GitHub publication."""

    print("GitHub publish preflight")
    print_key_value("Repository", str(repo_root))

    if not shutil.which("git"):
        print_key_value("Readiness", "blocked: git is not installed")
        return 1

    status, stdout, _ = git_capture(repo_root, "rev-parse", "--is-inside-work-tree")
    if status != 0 or stdout != "true":
        print_key_value("Readiness", "blocked: not a git worktree")
        return 1

    _, branch, _ = git_capture(repo_root, "branch", "--show-current")
    branch = branch or "(detached HEAD)"
    print_key_value("Branch", branch)

    remote_status, remote_url, remote_error = git_capture(repo_root, "remote", "get-url", "origin")
    if remote_status == 0:
        print_key_value("Origin", remote_url)
    else:
        print_key_value("Origin", f"missing ({remote_error or 'git remote get-url origin failed'})")

    status_status, status_output, status_error = git_capture(repo_root, "status", "--short")
    if status_status != 0:
        print_key_value("Worktree", f"unknown ({status_error or 'git status failed'})")
        return 1

    changed_paths = [line for line in status_output.splitlines() if line.strip()]
    if changed_paths:
        print_key_value("Worktree", f"dirty ({len(changed_paths)} paths)")
        for line in changed_paths[:40]:
            print(f"  {line}")
        if len(changed_paths) > 40:
            print(f"  ... {len(changed_paths) - 40} more paths")
    else:
        print_key_value("Worktree", "clean")

    upstream_status, upstream, upstream_error = git_capture(
        repo_root,
        "rev-parse",
        "--abbrev-ref",
        "--symbolic-full-name",
        "@{upstream}",
    )
    has_upstream = upstream_status == 0 and bool(upstream)
    print_key_value("Upstream", upstream if has_upstream else f"missing ({upstream_error or 'not configured'})")

    if has_upstream:
        ahead_status, ahead_behind, ahead_error = git_capture(
            repo_root,
            "rev-list",
            "--left-right",
            "--count",
            f"{upstream}...HEAD",
        )
        if ahead_status == 0 and ahead_behind:
            behind, ahead = ahead_behind.split()
            print_key_value("Ahead/behind", f"ahead {ahead}, behind {behind}")
        else:
            print_key_value("Ahead/behind", f"unknown ({ahead_error or 'rev-list failed'})")

    if shutil.which("gh"):
        gh_status, gh_stdout, gh_stderr = capture(["gh", "auth", "status", "--hostname", "github.com"])
        gh_text = "\n".join(part for part in [gh_stdout, gh_stderr] if part)
        if gh_status == 0:
            print_key_value("GitHub auth", "ok")
        else:
            print_key_value("GitHub auth", "blocked")
        if gh_text:
            for line in gh_text.splitlines():
                print(f"  {line}")
    else:
        gh_status = 1
        print_key_value("GitHub auth", "blocked: gh is not installed")

    blockers: list[str] = []
    warnings: list[str] = []

    if remote_status != 0:
        blockers.append("missing origin remote")
    if gh_status != 0:
        blockers.append("GitHub CLI is not authenticated")
    if branch in {"main", "master"}:
        warnings.append("current branch is a protected/default-style branch; create a topic branch before automation push")
    if branch == "(detached HEAD)":
        blockers.append("detached HEAD")
    if changed_paths:
        warnings.append("worktree has uncommitted changes; commit only the intended scoped files before pushing")
    if not has_upstream:
        warnings.append("branch has no upstream; first push should use `git push -u origin HEAD`")

    if blockers:
        print_key_value("Readiness", "blocked")
        for blocker in blockers:
            print(f"  - {blocker}")
    elif warnings:
        print_key_value("Readiness", "needs review before push")
        for warning in warnings:
            print(f"  - {warning}")
    else:
        print_key_value("Readiness", "ready to push committed changes")

    if blockers or (strict and warnings):
        return 1
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Run local skill market maintenance commands.")
    parser.add_argument(
        "command",
        choices=["sync", "audit", "develop", "publish-check"],
        help="Maintenance command to run",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="For publish-check, return non-zero when publication warnings remain.",
    )
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parents[1]
    if args.command == "sync":
        return sync(repo_root)
    if args.command == "audit":
        return audit(repo_root)
    if args.command == "publish-check":
        return publish_check(repo_root, strict=args.strict)
    return develop(repo_root)


if __name__ == "__main__":
    raise SystemExit(main())
