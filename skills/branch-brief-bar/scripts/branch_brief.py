#!/usr/bin/env python3
"""Render a local git branch brief for review handoff."""

from __future__ import annotations

import argparse
import json
import shutil
import subprocess
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path
from typing import Any


def run_git(repo: Path, args: list[str], check: bool = True) -> str:
    result = subprocess.run(
        ["git", "-C", str(repo), *args],
        check=False,
        capture_output=True,
        text=True,
    )
    if check and result.returncode != 0:
        message = result.stderr.strip() or result.stdout.strip() or "git command failed"
        raise RuntimeError(message)
    return result.stdout.rstrip("\n")


def resolve_repo(repo_arg: str) -> Path:
    candidate = Path(repo_arg).expanduser().resolve()
    try:
        root = run_git(candidate, ["rev-parse", "--show-toplevel"])
    except RuntimeError as exc:
        raise SystemExit(f"Error: {candidate} is not a git repository ({exc}).") from exc
    return Path(root)


def try_rev(repo: Path, ref: str) -> bool:
    result = subprocess.run(
        ["git", "-C", str(repo), "rev-parse", "--verify", ref],
        check=False,
        capture_output=True,
        text=True,
    )
    return result.returncode == 0


def current_branch(repo: Path) -> str:
    name = run_git(repo, ["branch", "--show-current"], check=False).strip()
    if name:
        return name
    return run_git(repo, ["rev-parse", "--short", "HEAD"])


def upstream_branch(repo: Path) -> str | None:
    upstream = run_git(repo, ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{upstream}"], check=False).strip()
    return upstream or None


def remote_head_base_ref(repo: Path) -> str | None:
    ref = run_git(repo, ["symbolic-ref", "refs/remotes/origin/HEAD"], check=False).strip()
    if ref.startswith("refs/remotes/"):
        return ref.removeprefix("refs/remotes/")
    return None


def same_named_upstream(branch: str, upstream: str | None) -> bool:
    if not upstream:
        return False
    return upstream == branch or upstream.endswith(f"/{branch}")


def main_like_candidates(repo: Path) -> list[str]:
    candidates: list[str] = []
    remote_head = remote_head_base_ref(repo)
    if remote_head:
        candidates.append(remote_head)
    candidates.extend(["origin/main", "main", "origin/master", "master", "origin/trunk", "trunk"])

    ordered: list[str] = []
    seen: set[str] = set()
    for candidate in candidates:
        if not candidate or candidate in seen:
            continue
        seen.add(candidate)
        ordered.append(candidate)
    return ordered


def default_base_ref(repo: Path, branch: str, upstream: str | None) -> tuple[str | None, str]:
    if upstream and not same_named_upstream(branch, upstream):
        return upstream, "upstream branch"

    remote_head = remote_head_base_ref(repo)
    # When the upstream only mirrors the current feature branch, prefer a review
    # branch over the push target so the brief stays PR-oriented by default.
    for candidate in main_like_candidates(repo):
        if try_rev(repo, candidate):
            if candidate == remote_head:
                return candidate, "remote default branch"
            return candidate, "main-like branch fallback"

    if upstream:
        return upstream, "same-name upstream fallback"

    if try_rev(repo, "HEAD~1"):
        return "HEAD~1", "previous commit fallback"

    return None, "no compare base"


def resolve_base_ref(repo: Path, requested: str | None, branch: str, upstream: str | None) -> tuple[str | None, str]:
    if requested:
        candidate = requested.strip()
        if not candidate:
            return default_base_ref(repo, branch, upstream)
        if not try_rev(repo, candidate):
            raise SystemExit(f"Error: compare base {candidate!r} does not resolve in {repo}.")
        return candidate, "explicit --base-ref"
    return default_base_ref(repo, branch, upstream)


def ahead_behind(repo: Path, upstream: str | None) -> tuple[int, int]:
    if not upstream:
        return (0, 0)
    counts = run_git(repo, ["rev-list", "--left-right", "--count", f"{upstream}...HEAD"])
    left, right = counts.split()
    return (int(right), int(left))


def normalize_status_path(raw_path: str) -> str:
    path = raw_path.strip()
    if " -> " in path:
        return path.split(" -> ", 1)[1].strip()
    return path


def parse_status(repo: Path) -> dict[str, Any]:
    lines = run_git(repo, ["status", "--porcelain=1", "--untracked-files=all"], check=False).splitlines()
    entries_by_path: dict[str, dict[str, Any]] = {}
    counts = Counter({"staged": 0, "unstaged": 0, "untracked": 0})

    for line in lines:
        if not line:
            continue
        status = line[:2]
        path = normalize_status_path(line[3:])
        x, y = status[0], status[1]

        if status == "??":
            counts["untracked"] += 1
            entries_by_path[path] = {
                "path": path,
                "state": "untracked",
                "staged": False,
                "unstaged": False,
                "untracked": True,
            }
            continue

        if x != " ":
            counts["staged"] += 1
        if y != " ":
            counts["unstaged"] += 1

        state = "modified"
        if "R" in status:
            state = "renamed"
        elif "D" in status:
            state = "deleted"
        elif "A" in status:
            state = "added"

        entry = entries_by_path.setdefault(
            path,
            {
                "path": path,
                "state": state,
                "staged": False,
                "unstaged": False,
                "untracked": False,
            },
        )
        entry["state"] = state
        if x != " ":
            entry["staged"] = True
        if y != " ":
            entry["unstaged"] = True

    return {
        "entries": list(entries_by_path.values()),
        "staged": counts["staged"],
        "unstaged": counts["unstaged"],
        "untracked": counts["untracked"],
    }


def compare_paths(repo: Path, base_ref: str | None) -> list[str]:
    if not base_ref:
        return []
    output = run_git(repo, ["diff", "--name-only", f"{base_ref}...HEAD"], check=False)
    return [line.strip() for line in output.splitlines() if line.strip()]


def summarize_area(path: str) -> str:
    parts = Path(path).parts
    if not parts:
        return path
    if parts[0] in {"skills", "apps", "collections", "catalog", "scripts"} and len(parts) >= 2:
        return "/".join(parts[:2])
    if len(parts) >= 2 and parts[0] == "prototype":
        return "/".join(parts[:2])
    return parts[0]


def unique_preserving_order(values: list[str]) -> list[str]:
    seen: set[str] = set()
    ordered: list[str] = []
    for value in values:
        if value in seen:
            continue
        seen.add(value)
        ordered.append(value)
    return ordered


def changed_file_status_label(path: str, *, committed: bool, entry: dict[str, Any] | None) -> str:
    labels: list[str] = []
    state = str(entry.get("state", "")).strip().lower() if entry else ""

    if state in {"added", "deleted", "renamed"} and not (state == "added" and entry and entry.get("untracked")):
        labels.append(state)

    if committed:
        labels.append("committed")

    if entry:
        if entry.get("staged"):
            labels.append("staged")
        if entry.get("unstaged"):
            labels.append("unstaged")
        if entry.get("untracked"):
            labels.append("untracked")

    if not labels:
        labels.append("modified")

    return " + ".join(unique_preserving_order(labels))


def changed_file_preview_details(
    changed_paths: list[str],
    diff_paths: list[str],
    status_entries: list[dict[str, Any]],
    max_files: int,
) -> list[dict[str, str]]:
    diff_set = set(diff_paths)
    status_by_path = {str(entry.get("path", "")).strip(): entry for entry in status_entries}
    preview: list[dict[str, str]] = []

    for path in changed_paths[:max_files]:
        entry = status_by_path.get(path)
        preview.append(
            {
                "path": path,
                "status": changed_file_status_label(path, committed=path in diff_set, entry=entry),
            }
        )

    return preview


def recent_commits(repo: Path, base_ref: str | None, max_commits: int) -> list[dict[str, str]]:
    log_args = ["log", "--format=%h%x09%s", f"-n{max_commits}"]
    if base_ref and try_rev(repo, base_ref):
        range_output = run_git(repo, [*log_args, f"{base_ref}..HEAD"], check=False)
        if range_output.strip():
            return [parse_commit_line(line) for line in range_output.splitlines() if line.strip()]
    output = run_git(repo, log_args, check=False)
    return [parse_commit_line(line) for line in output.splitlines() if line.strip()]


def parse_commit_line(line: str) -> dict[str, str]:
    sha, _, subject = line.partition("\t")
    return {"sha": sha.strip(), "subject": subject.strip()}


def next_action(ahead: int, behind: int, staged: int, unstaged: int, untracked: int, upstream: str | None) -> str:
    dirty = staged + unstaged + untracked
    if behind > 0 and dirty > 0:
        return "Rebase or merge the upstream branch before opening or updating the PR."
    if behind > 0:
        return "Pull or rebase onto the upstream branch before asking for review."
    if not upstream:
        return "Decide the PR target or set an upstream branch before sharing this work."
    if dirty > 0 and staged == 0:
        return "Review and stage the current working tree before opening or updating the PR."
    if dirty > 0:
        return "Finish the staged change set, run checks, and commit before opening or updating the PR."
    if ahead > 0:
        return "Open or update the PR and paste the brief into the review thread."
    return "The branch is clean and synced locally; no immediate PR handoff is needed."


def build_brief(
    repo: Path,
    max_commits: int,
    max_areas: int,
    max_files: int,
    requested_base_ref: str | None = None,
) -> dict[str, Any]:
    branch = current_branch(repo)
    upstream = upstream_branch(repo)
    base_ref, base_ref_source = resolve_base_ref(repo, requested_base_ref, branch, upstream)
    ahead, behind = ahead_behind(repo, upstream)
    status = parse_status(repo)
    diff_paths = compare_paths(repo, base_ref)
    working_tree_paths = [entry["path"] for entry in status["entries"]]
    changed_paths = unique_preserving_order(diff_paths + working_tree_paths)
    touched_areas = unique_preserving_order([summarize_area(path) for path in changed_paths])[:max_areas]
    preview_details = changed_file_preview_details(changed_paths, diff_paths, status["entries"], max_files)
    changed_file_preview = [item["path"] for item in preview_details]
    commits = recent_commits(repo, base_ref, max_commits)
    recommended = next_action(
        ahead=ahead,
        behind=behind,
        staged=status["staged"],
        unstaged=status["unstaged"],
        untracked=status["untracked"],
        upstream=upstream,
    )

    return {
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "repo_root": str(repo),
        "repo_name": repo.name,
        "branch": branch,
        "upstream": upstream,
        "base_ref": base_ref,
        "base_ref_source": base_ref_source,
        "ahead": ahead,
        "behind": behind,
        "staged_count": status["staged"],
        "unstaged_count": status["unstaged"],
        "untracked_count": status["untracked"],
        "dirty_file_count": status["staged"] + status["unstaged"] + status["untracked"],
        "changed_paths": changed_paths,
        "changed_file_count": len(changed_paths),
        "changed_file_preview": changed_file_preview,
        "changed_file_preview_details": preview_details,
        "touched_areas": touched_areas,
        "recent_commits": commits,
        "next_action": recommended,
    }


def preview_text_items(brief: dict[str, Any]) -> list[str]:
    details = brief.get("changed_file_preview_details")
    if isinstance(details, list):
        rendered: list[str] = []
        for item in details:
            if not isinstance(item, dict):
                continue
            path = str(item.get("path", "")).strip()
            status = str(item.get("status", "")).strip()
            if not path:
                continue
            rendered.append(f"{path} [{status}]" if status else path)
        if rendered:
            return rendered

    return [str(path) for path in brief.get("changed_file_preview", [])]


def render_markdown(brief: dict[str, Any]) -> str:
    upstream = brief["upstream"] or "none"
    base_ref = brief["base_ref"] or "none"
    base_ref_source = brief.get("base_ref_source") or "unknown"
    preview_items = preview_text_items(brief)
    lines = [
        f"# Branch Brief: {brief['repo_name']}",
        "",
        f"- Branch: `{brief['branch']}`",
        f"- Upstream: `{upstream}`",
        f"- Compare base: `{base_ref}` ({base_ref_source})",
        f"- Ahead: `{brief['ahead']}`",
        f"- Behind: `{brief['behind']}`",
        f"- Working tree: `{brief['staged_count']}` staged, `{brief['unstaged_count']}` unstaged, `{brief['untracked_count']}` untracked",
        "",
        "## Touched Areas",
        "",
    ]
    if brief["touched_areas"]:
        lines.extend([f"- `{area}`" for area in brief["touched_areas"]])
    else:
        lines.append("- No changed areas detected")
    lines.extend(["", "## Changed Files", ""])
    if preview_items:
        lines.extend([f"- `{item}`" for item in preview_items])
        remaining = brief["changed_file_count"] - len(preview_items)
        if remaining > 0:
            lines.append(f"- ...and `{remaining}` more")
    else:
        lines.append("- No changed files detected")
    lines.extend(["", "## Recent Commits", ""])
    if brief["recent_commits"]:
        lines.extend([f"- `{item['sha']}` {item['subject']}" for item in brief["recent_commits"]])
    else:
        lines.append("- No recent commits found")
    lines.extend(["", "## Next Action", "", f"- {brief['next_action']}"])
    return "\n".join(lines)


def render_prompt(brief: dict[str, Any]) -> str:
    upstream = brief["upstream"] or "none"
    base_ref = brief["base_ref"] or "none"
    base_ref_source = brief.get("base_ref_source") or "unknown"
    commits = "; ".join(f"{item['sha']} {item['subject']}" for item in brief["recent_commits"]) or "none"
    areas = ", ".join(brief["touched_areas"]) or "none"
    preview_items = preview_text_items(brief)
    files = ", ".join(preview_items) or "none"
    remaining = brief["changed_file_count"] - len(preview_items)
    if remaining > 0:
        files = f"{files} (+{remaining} more)"
    return "\n".join(
        [
            f"Repo: {brief['repo_name']}",
            f"Branch: {brief['branch']}",
            f"Upstream: {upstream}",
            f"Compare base: {base_ref} ({base_ref_source})",
            f"Ahead/Behind: {brief['ahead']}/{brief['behind']}",
            f"Working tree: staged {brief['staged_count']}, unstaged {brief['unstaged_count']}, untracked {brief['untracked_count']}",
            f"Touched areas: {areas}",
            f"Changed files: {files}",
            f"Recent commits: {commits}",
            f"Next action: {brief['next_action']}",
        ]
    )


def render_plain(brief: dict[str, Any]) -> str:
    upstream = brief["upstream"] or "no upstream"
    base_ref = brief["base_ref"] or "no compare base"
    base_ref_source = brief.get("base_ref_source") or "unknown compare rule"
    areas = ", ".join(brief["touched_areas"]) or "no changed areas"
    preview_items = preview_text_items(brief)
    files = ", ".join(preview_items) or "no changed files"
    remaining = brief["changed_file_count"] - len(preview_items)
    if remaining > 0:
        files = f"{files}, plus {remaining} more"
    commits = ", ".join(f"{item['sha']} {item['subject']}" for item in brief["recent_commits"]) or "no recent commits"
    return (
        f"{brief['repo_name']} on branch {brief['branch']} is working against {upstream}. "
        f"The brief compares against {base_ref} via {base_ref_source}. "
        f"It is {brief['ahead']} commits ahead and {brief['behind']} behind. "
        f"The working tree has {brief['staged_count']} staged, {brief['unstaged_count']} unstaged, "
        f"and {brief['untracked_count']} untracked items. "
        f"Touched areas: {areas}. Changed files: {files}. Recent commits: {commits}. "
        f"Next action: {brief['next_action']}"
    )


def render_output(brief: dict[str, Any], output_format: str) -> str:
    if output_format == "json":
        return json.dumps(brief, indent=2, ensure_ascii=True) + "\n"
    if output_format == "markdown":
        return render_markdown(brief) + "\n"
    if output_format == "prompt":
        return render_prompt(brief) + "\n"
    return render_plain(brief) + "\n"


def copy_to_clipboard(text: str) -> None:
    if not shutil.which("pbcopy"):
        raise SystemExit("Error: pbcopy is not available on this system.")
    subprocess.run(["pbcopy"], input=text, text=True, check=True)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Render a local git branch brief for review handoff.")
    parser.add_argument("command", choices=["current", "copy"], help="Print the brief or copy it to the clipboard.")
    parser.add_argument("--repo", default=".", help="Repo path to inspect. Defaults to the current directory.")
    parser.add_argument(
        "--base-ref",
        help="Optional git ref to compare against for touched areas and recent commits. Defaults to upstream, then a main-like branch such as origin/HEAD, main, master, or trunk, then HEAD~1.",
    )
    parser.add_argument("--format", choices=["plain", "markdown", "prompt", "json"], default="prompt")
    parser.add_argument("--max-commits", type=int, default=5, help="How many recent commits to include.")
    parser.add_argument("--max-areas", type=int, default=6, help="How many touched areas to include.")
    parser.add_argument("--max-files", type=int, default=5, help="How many changed file paths to preview.")
    return parser


def main() -> int:
    parser = build_parser()
    args = parser.parse_args()

    repo = resolve_repo(args.repo)
    brief = build_brief(
        repo=repo,
        max_commits=max(1, args.max_commits),
        max_areas=max(1, args.max_areas),
        max_files=max(1, args.max_files),
        requested_base_ref=args.base_ref,
    )
    rendered = render_output(brief, args.format)

    if args.command == "copy":
        copy_to_clipboard(rendered)
        print(
            f"Copied {args.format} branch brief for {brief['repo_name']} on {brief['branch']} to the clipboard.",
            file=sys.stderr,
        )
        return 0

    sys.stdout.write(rendered)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
