#!/usr/bin/env python3
"""Summarize today's git activity and generate a grounded reminder story."""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from dataclasses import dataclass
from datetime import date, timedelta
from pathlib import Path


@dataclass
class DayStats:
    commits: int
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
        "--pretty=format:__COMMIT__",
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


def collect_stats(repo: Path, since: date, until: date, author: str | None, branch: str | None) -> DayStats:
    output = run_git_log(repo, since, until, author, branch)
    commits = 0
    files_changed = 0
    additions = 0
    deletions = 0

    for raw_line in output.splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line == "__COMMIT__":
            commits += 1
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

    return DayStats(
        commits=commits,
        files_changed=files_changed,
        additions=additions,
        deletions=deletions,
    )


def collect_daily_series(repo: Path, end_day: date, days: int, author: str | None, branch: str | None) -> list[tuple[date, DayStats]]:
    series: list[tuple[date, DayStats]] = []
    for offset in range(days - 1, -1, -1):
        day = end_day - timedelta(days=offset)
        series.append((day, collect_stats(repo, day, day, author, branch)))
    return series


def average(values: list[float]) -> float:
    return sum(values) / len(values) if values else 0.0


def streak_length(series: list[tuple[date, DayStats]]) -> int:
    streak = 0
    for _, stats in reversed(series):
        if stats.commits > 0:
            streak += 1
        else:
            break
    return streak


def story_line(today: DayStats, avg_commits_7: float, avg_lines_7: float, streak: int, target_multiplier: float | None) -> str:
    if today.commits == 0 and today.lines_changed == 0:
        base = "No commits landed today yet, so the move is to restart the streak with one real push instead of waiting for a perfect session."
    elif today.commits >= max(3, avg_commits_7):
        base = "Today already looks like a real forward day, not a maintenance blur. The work is visible, and the graph is moving."
    elif today.lines_changed >= max(250, avg_lines_7):
        base = "The commit count is modest, but the code churn says real work moved. This is one of those days where substance matters more than volume."
    else:
        base = "Today is on the board, and that matters. Small visible progress is still how long compounding runs get built."

    streak_line = f"The current active streak is {streak} day{'s' if streak != 1 else ''}."
    if target_multiplier is not None:
        goal_line = f"Keep stacking days like this and the long-run path toward {target_multiplier:.0f}x stays believable."
    else:
        goal_line = "Keep stacking days like this and the longer-term gain stays real."
    return f"{base} {streak_line} {goal_line}"


def build_report(repo: Path, today_day: date, today: DayStats, series_7: list[tuple[date, DayStats]], series_30: list[tuple[date, DayStats]], target_multiplier: float | None, author: str | None) -> dict[str, object]:
    commits_7 = [float(stats.commits) for _, stats in series_7]
    commits_30 = [float(stats.commits) for _, stats in series_30]
    lines_7 = [float(stats.lines_changed) for _, stats in series_7]
    lines_30 = [float(stats.lines_changed) for _, stats in series_30]
    active_days_7 = sum(1 for _, stats in series_7 if stats.commits > 0)
    active_days_30 = sum(1 for _, stats in series_30 if stats.commits > 0)
    avg_commits_7 = average(commits_7)
    avg_commits_30 = average(commits_30)
    avg_lines_7 = average(lines_7)
    avg_lines_30 = average(lines_30)
    streak = streak_length(series_30)

    return {
        "repo": str(repo),
        "date": today_day.isoformat(),
        "author": author,
        "today": {
            "commits": today.commits,
            "files_changed": today.files_changed,
            "additions": today.additions,
            "deletions": today.deletions,
            "lines_changed": today.lines_changed,
        },
        "seven_day": {
            "commit_total": sum(int(v) for v in commits_7),
            "commit_avg": avg_commits_7,
            "lines_changed_total": sum(int(v) for v in lines_7),
            "lines_changed_avg": avg_lines_7,
            "active_days": active_days_7,
        },
        "thirty_day": {
            "commit_total": sum(int(v) for v in commits_30),
            "commit_avg": avg_commits_30,
            "lines_changed_total": sum(int(v) for v in lines_30),
            "lines_changed_avg": avg_lines_30,
            "active_days": active_days_30,
        },
        "streak_days": streak,
        "target_multiplier": target_multiplier,
        "story": story_line(today, avg_commits_7, avg_lines_7, streak, target_multiplier),
    }


def render_text(report: dict[str, object]) -> str:
    today = report["today"]
    seven_day = report["seven_day"]
    thirty_day = report["thirty_day"]
    lines = [
        f"Date: {report['date']}",
        f"Repo: {report['repo']}",
        f"Today's commits: {today['commits']}",
        f"Today's files changed: {today['files_changed']}",
        f"Today's lines changed: {today['lines_changed']} (+{today['additions']} / -{today['deletions']})",
        f"7-day commits: {seven_day['commit_total']} total, {seven_day['commit_avg']:.2f}/day average",
        f"7-day lines changed: {seven_day['lines_changed_total']} total, {seven_day['lines_changed_avg']:.2f}/day average",
        f"30-day commits: {thirty_day['commit_total']} total, {thirty_day['commit_avg']:.2f}/day average",
        f"30-day lines changed: {thirty_day['lines_changed_total']} total, {thirty_day['lines_changed_avg']:.2f}/day average",
        f"Active streak: {report['streak_days']} day{'s' if report['streak_days'] != 1 else ''}",
        "",
        f"Reminder story: {report['story']}",
    ]
    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate a daily git productivity story.")
    parser.add_argument("--repo", required=True, help="Path to the git repository")
    parser.add_argument("--date", type=parse_iso_date, default=date.today(), help="Day to summarize in YYYY-MM-DD, defaults to today")
    parser.add_argument("--author", help="Optional git author filter")
    parser.add_argument("--branch", help="Optional branch or revision range")
    parser.add_argument("--target-multiplier", type=float, help="Optional long-run multiplier goal such as 90")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text")
    args = parser.parse_args()

    repo = Path(args.repo).expanduser().resolve()
    if not (repo / ".git").exists():
        print(f"Error: not a git repository: {repo}", file=sys.stderr)
        return 1

    try:
        today_stats = collect_stats(repo, args.date, args.date, args.author, args.branch)
        series_7 = collect_daily_series(repo, args.date, 7, args.author, args.branch)
        series_30 = collect_daily_series(repo, args.date, 30, args.author, args.branch)
    except RuntimeError as exc:
        print(f"Error: {exc}", file=sys.stderr)
        return 1

    report = build_report(repo, args.date, today_stats, series_7, series_30, args.target_multiplier, args.author)
    if args.json:
        json.dump(report, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        sys.stdout.write(render_text(report))
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
