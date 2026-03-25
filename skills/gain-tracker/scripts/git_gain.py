#!/usr/bin/env python3
"""Compare git productivity across two time windows."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import date
from pathlib import Path

from gain_math import build_report, positive_number, render_text
from tracker_config import default_author_pattern, is_git_repo, load_config, repo_entry_from_path, tracked_repo_entries


@dataclass
class WindowStats:
    commit_count: int
    active_days: int
    files_changed: int
    additions: int
    deletions: int

    @property
    def lines_changed(self) -> int:
        return self.additions + self.deletions


def parse_iso_date(raw: str) -> date:
    try:
        return date.fromisoformat(raw)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid ISO date: {raw}") from exc


def inclusive_days(start: date, end: date) -> float:
    if end < start:
        raise ValueError(f"end date {end.isoformat()} is before start date {start.isoformat()}")
    return float((end - start).days + 1)


def git_since_arg(day: date) -> str:
    return f"{day.isoformat()} 00:00:00"


def git_until_arg(day: date) -> str:
    return f"{day.isoformat()} 23:59:59"


def run_git_log(repo: Path, since: date, until: date, author: str | None, branch: str | None) -> str:
    cmd = [
        "git",
        "-C",
        str(repo),
        "log",
        "--no-merges",
        "--since",
        git_since_arg(since),
        "--until",
        git_until_arg(until),
        "--numstat",
        "--date=short",
        "--pretty=format:__COMMIT__%n%ad",
    ]
    if author:
        cmd.extend(["--author", author])
    if branch:
        cmd.append(branch)

    result = subprocess.run(cmd, capture_output=True, text=True, check=False)
    if result.returncode != 0:
        stderr = result.stderr.strip() or "git log failed"
        raise RuntimeError(stderr)
    return result.stdout


def collect_window_stats(repo: Path, since: date, until: date, author: str | None, branch: str | None) -> WindowStats:
    output = run_git_log(repo, since, until, author, branch)
    commits = 0
    files_changed = 0
    additions = 0
    deletions = 0
    active_days: set[str] = set()
    expect_date = False

    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line == "__COMMIT__":
            commits += 1
            expect_date = True
            continue
        if expect_date:
            active_days.add(line)
            expect_date = False
            continue

        parts = raw_line.split("\t")
        if len(parts) != 3:
            continue
        if parts[0] == "-" or parts[1] == "-":
            continue
        try:
            additions += int(parts[0])
            deletions += int(parts[1])
        except ValueError:
            continue
        files_changed += 1

    return WindowStats(
        commit_count=commits,
        active_days=len(active_days),
        files_changed=files_changed,
        additions=additions,
        deletions=deletions,
    )


def metric_total(stats: WindowStats, metric: str) -> float:
    if metric == "commits":
        return float(stats.commit_count)
    if metric == "lines-changed":
        return float(stats.lines_changed)
    if metric == "files-changed":
        return float(stats.files_changed)
    if metric == "active-days":
        return float(stats.active_days)
    raise ValueError(f"unsupported metric: {metric}")


def render_git_text(report: dict[str, object], baseline: WindowStats, current: WindowStats, metric: str) -> str:
    lines = [
        f"Repo: {report.get('repo_label', report['repo'])}",
        f"Author filter: {report.get('author', '') or 'none'}",
        f"Repo metric: {metric}",
        f"Baseline commits: {baseline.commit_count}",
        f"Baseline active days: {baseline.active_days}",
        f"Baseline files changed: {baseline.files_changed}",
        f"Baseline lines changed: {baseline.lines_changed}",
        f"Current commits: {current.commit_count}",
        f"Current active days: {current.active_days}",
        f"Current files changed: {current.files_changed}",
        f"Current lines changed: {current.lines_changed}",
        "",
        render_text(report),
    ]
    return "\n".join(lines)


def resolve_repo(repo_arg: str | None, config: dict[str, object]) -> dict[str, object]:
    if repo_arg:
        return repo_entry_from_path(Path(repo_arg))

    cwd = Path.cwd()
    if is_git_repo(cwd):
        return repo_entry_from_path(cwd)

    tracked = tracked_repo_entries(config)
    if tracked:
        return tracked[0]

    raise RuntimeError("no repo provided and no tracked repos are connected; run github_connect.py connect --repo /path/to/repo")


def main() -> int:
    parser = argparse.ArgumentParser(description="Compare git productivity across two time windows.")
    parser.add_argument("--repo", help="Path to the git repository. Defaults to the current repo or first tracked repo.")
    parser.add_argument("--baseline-since", required=True, type=parse_iso_date, help="Baseline window start date in YYYY-MM-DD")
    parser.add_argument("--baseline-until", required=True, type=parse_iso_date, help="Baseline window end date in YYYY-MM-DD")
    parser.add_argument("--current-since", required=True, type=parse_iso_date, help="Current window start date in YYYY-MM-DD")
    parser.add_argument("--current-until", required=True, type=parse_iso_date, help="Current window end date in YYYY-MM-DD")
    parser.add_argument("--metric", default="commits", choices=["commits", "lines-changed", "files-changed", "active-days"], help="Git metric to compare")
    parser.add_argument("--goal-multiplier", required=True, type=positive_number, help="Target multiplier, for example 90 or 90x")
    parser.add_argument("--author", help="Optional git author filter")
    parser.add_argument("--branch", help="Optional branch or revision range")
    parser.add_argument("--label", default="git productivity gain", help="Human-readable label for the report")
    parser.add_argument("--driver", action="append", default=[], help="Optional driver behind the gain, such as GStack")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text")
    args = parser.parse_args()

    config = load_config()

    try:
        repo_entry = resolve_repo(args.repo, config)
        repo = Path(str(repo_entry["path"])).expanduser().resolve()
        author = args.author or default_author_pattern(config, repo_entry)
        baseline_days = inclusive_days(args.baseline_since, args.baseline_until)
        current_days = inclusive_days(args.current_since, args.current_until)
        baseline_stats = collect_window_stats(repo, args.baseline_since, args.baseline_until, author, args.branch)
        current_stats = collect_window_stats(repo, args.current_since, args.current_until, author, args.branch)
        baseline_total = metric_total(baseline_stats, args.metric)
        current_total = metric_total(current_stats, args.metric)
        if baseline_total <= 0 or current_total <= 0:
            print("Error: selected windows must both produce a positive metric total", file=sys.stderr)
            return 1
    except (RuntimeError, ValueError) as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    gain_args = argparse.Namespace(
        baseline_output=baseline_total,
        baseline_days=baseline_days,
        current_output=current_total,
        current_days=current_days,
        goal_multiplier=args.goal_multiplier,
        label=args.label,
        metric=args.metric,
        driver=args.driver,
    )
    report = build_report(gain_args)
    report.update(
        {
            "repo": str(repo),
            "repo_label": str(repo_entry.get("full_name", repo.name)),
            "author": author,
            "baseline_window": {
                "since": args.baseline_since.isoformat(),
                "until": args.baseline_until.isoformat(),
                "days": baseline_days,
                "stats": {
                    "commits": baseline_stats.commit_count,
                    "active_days": baseline_stats.active_days,
                    "files_changed": baseline_stats.files_changed,
                    "additions": baseline_stats.additions,
                    "deletions": baseline_stats.deletions,
                    "lines_changed": baseline_stats.lines_changed,
                },
            },
            "current_window": {
                "since": args.current_since.isoformat(),
                "until": args.current_until.isoformat(),
                "days": current_days,
                "stats": {
                    "commits": current_stats.commit_count,
                    "active_days": current_stats.active_days,
                    "files_changed": current_stats.files_changed,
                    "additions": current_stats.additions,
                    "deletions": current_stats.deletions,
                    "lines_changed": current_stats.lines_changed,
                },
            },
        }
    )

    if args.json:
        json.dump(report, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
        return 0

    sys.stdout.write(render_git_text(report, baseline_stats, current_stats, args.metric))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
