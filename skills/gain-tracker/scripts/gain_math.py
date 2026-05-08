#!/usr/bin/env python3
"""Compute output gain multipliers against a historical baseline."""

from __future__ import annotations

import argparse
import json
import sys


def positive_number(raw: str) -> float:
    cleaned = raw.strip().lower().rstrip("x")
    try:
        value = float(cleaned)
    except ValueError as exc:
        raise argparse.ArgumentTypeError(f"invalid number: {raw}") from exc
    if value <= 0:
        raise argparse.ArgumentTypeError(f"value must be greater than zero: {raw}")
    return value


def build_report(args: argparse.Namespace) -> dict[str, object]:
    baseline_rate = args.baseline_output / args.baseline_days
    current_rate = args.current_output / args.current_days
    current_multiplier = current_rate / baseline_rate
    goal_progress = current_multiplier / args.goal_multiplier
    goal_rate = baseline_rate * args.goal_multiplier
    target_output_for_current_window = goal_rate * args.current_days
    additional_output_needed = max(0.0, target_output_for_current_window - args.current_output)
    baseline_equivalent_current_window = baseline_rate * args.current_days
    output_delta = args.current_output - baseline_equivalent_current_window

    return {
        "label": args.label,
        "metric": args.metric,
        "baseline_output": args.baseline_output,
        "baseline_days": args.baseline_days,
        "baseline_rate_per_day": baseline_rate,
        "current_output": args.current_output,
        "current_days": args.current_days,
        "current_rate_per_day": current_rate,
        "current_multiplier": current_multiplier,
        "goal_multiplier": args.goal_multiplier,
        "goal_progress_ratio": goal_progress,
        "goal_progress_percent": goal_progress * 100.0,
        "target_output_for_current_window": target_output_for_current_window,
        "additional_output_needed_for_goal": additional_output_needed,
        "current_output_delta_vs_baseline_window": output_delta,
        "drivers": args.driver,
    }


def render_text(report: dict[str, object]) -> str:
    lines = [
        f"Label: {report['label']}",
        f"Metric: {report['metric']}",
        f"Baseline: {report['baseline_output']:.2f} over {report['baseline_days']:.2f} days",
        f"Current: {report['current_output']:.2f} over {report['current_days']:.2f} days",
        f"Baseline rate/day: {report['baseline_rate_per_day']:.4f}",
        f"Current rate/day: {report['current_rate_per_day']:.4f}",
        f"Current multiplier: {report['current_multiplier']:.2f}x",
        f"Goal multiplier: {report['goal_multiplier']:.2f}x",
        f"Goal progress: {report['goal_progress_percent']:.2f}%",
        f"Target output for current window: {report['target_output_for_current_window']:.2f}",
        f"Additional output needed for goal: {report['additional_output_needed_for_goal']:.2f}",
        f"Current delta vs baseline-equivalent window: {report['current_output_delta_vs_baseline_window']:.2f}",
    ]

    drivers = report["drivers"]
    if drivers:
        lines.append(f"Drivers: {', '.join(drivers)}")

    return "\n".join(lines)


def main() -> int:
    parser = argparse.ArgumentParser(description="Track gain multipliers against a baseline.")
    parser.add_argument("--baseline-output", required=True, type=positive_number, help="Baseline total output")
    parser.add_argument("--baseline-days", required=True, type=positive_number, help="Number of days in the baseline window")
    parser.add_argument("--current-output", required=True, type=positive_number, help="Current total output")
    parser.add_argument("--current-days", required=True, type=positive_number, help="Number of days in the current window")
    parser.add_argument("--goal-multiplier", required=True, type=positive_number, help="Target multiplier, for example 90 or 90x")
    parser.add_argument("--label", default="output gain", help="Human-readable label for the report")
    parser.add_argument("--metric", default="output units", help="Name of the metric being compared")
    parser.add_argument("--driver", action="append", default=[], help="Optional driver behind the gain, such as GStack")
    parser.add_argument("--json", action="store_true", help="Print JSON instead of text")
    args = parser.parse_args()

    report = build_report(args)
    if args.json:
        json.dump(report, sys.stdout, indent=2, sort_keys=True)
        sys.stdout.write("\n")
    else:
        sys.stdout.write(render_text(report))
        sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
