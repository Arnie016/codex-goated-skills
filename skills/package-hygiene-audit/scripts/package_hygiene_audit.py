#!/usr/bin/env python3
"""Audit a local macOS release folder before shipping."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable


ARCHIVE_SUFFIXES = (".dmg", ".pkg", ".zip", ".tar.gz", ".tgz")
NOTE_SUFFIXES = {".md", ".markdown", ".txt", ".rtf"}
SCREENSHOT_SUFFIXES = {".png", ".jpg", ".jpeg", ".heic", ".webp"}
NOTE_KEYWORDS = ("release", "notes", "changelog", "whats-new", "what-s-new", "readme")
SCREENSHOT_DIR_HINTS = ("screenshot", "screenshots", "shots", "media")
VERSION_PATTERN = re.compile(r"(?:^|[-_v])(\d+(?:[._-]\d+){1,})", re.IGNORECASE)


@dataclass
class Artifact:
    kind: str
    path: str
    name: str
    modified_at: str

    def as_dict(self) -> dict[str, str]:
        return asdict(self)


@dataclass
class CheckResult:
    key: str
    label: str
    status: str
    detail: str

    def as_dict(self) -> dict[str, str]:
        return asdict(self)


@dataclass
class AuditReport:
    generated_at: str
    release_dir: str
    summary: str
    checks: list[CheckResult]
    blocking_issues: list[str]
    warnings: list[str]
    app_bundles: list[Artifact]
    archives: list[Artifact]
    release_notes: list[Artifact]
    screenshots: list[Artifact]
    next_actions: list[str]

    def as_dict(self) -> dict[str, object]:
        return {
            "generated_at": self.generated_at,
            "release_dir": self.release_dir,
            "summary": self.summary,
            "checks": [item.as_dict() for item in self.checks],
            "blocking_issues": self.blocking_issues,
            "warnings": self.warnings,
            "app_bundles": [item.as_dict() for item in self.app_bundles],
            "archives": [item.as_dict() for item in self.archives],
            "release_notes": [item.as_dict() for item in self.release_notes],
            "screenshots": [item.as_dict() for item in self.screenshots],
            "next_actions": self.next_actions,
        }


def utc_now() -> str:
    return datetime.now(timezone.utc).replace(microsecond=0).isoformat()


def fail(message: str) -> None:
    raise SystemExit(f"Error: {message}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Audit a local release packaging folder.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    def add_common_arguments(command_parser: argparse.ArgumentParser) -> None:
        command_parser.add_argument(
            "--release-dir",
            type=Path,
            default=Path.cwd(),
            help="Folder containing the current release artifacts (default: current directory)",
        )
        command_parser.add_argument(
            "--notes-path",
            type=Path,
            action="append",
            default=[],
            help="Optional note file or folder to search when release notes live outside the release folder",
        )
        command_parser.add_argument(
            "--screenshot-dir",
            type=Path,
            help="Optional screenshot folder when screenshots live outside the release folder",
        )
        command_parser.add_argument(
            "--expect-app-name",
            default="",
            help="Optional product name that should appear in bundle or archive names",
        )
        command_parser.add_argument(
            "--minimum-screenshots",
            type=int,
            default=1,
            help="Minimum screenshot count required for this packaging lane (default: 1)",
        )

    doctor = subparsers.add_parser("doctor", help="Check path resolution before auditing")
    add_common_arguments(doctor)
    doctor.add_argument(
        "--format",
        choices=("markdown", "json"),
        default="markdown",
        help="Output format for doctor checks",
    )

    audit = subparsers.add_parser("audit", help="Audit the release folder")
    add_common_arguments(audit)
    audit.add_argument(
        "--require-packaged-archive",
        action="store_true",
        help="Treat missing packaged archives such as .dmg or .zip as blocking",
    )
    audit.add_argument(
        "--format",
        choices=("markdown", "json", "prompt"),
        default="markdown",
        help="Output format for the audit",
    )
    return parser.parse_args()


def existing_path(path: Path) -> Path | None:
    candidate = path.expanduser().resolve()
    if candidate.exists():
        return candidate
    return None


def require_existing_path(path: Path, *, label: str) -> Path:
    candidate = existing_path(path)
    if candidate is None:
        fail(f"{label} not found: {path}")
    return candidate


def walk_visible_paths(root: Path, *, max_depth: int) -> Iterable[Path]:
    root = root.resolve()
    if not root.is_dir():
        return

    for current_root, dirnames, filenames in os.walk(root):
        current_path = Path(current_root)
        relative = current_path.relative_to(root)
        depth = len(relative.parts)
        dirnames[:] = [name for name in dirnames if not name.startswith(".")]

        if current_path.name.endswith(".app"):
            yield current_path
            dirnames[:] = []
            continue

        if depth >= max_depth:
            dirnames[:] = []

        for filename in filenames:
            if filename.startswith("."):
                continue
            yield current_path / filename


def normalize_name(value: str) -> str:
    pieces = []
    previous_dash = False
    for character in value.lower():
        if character.isalnum():
            pieces.append(character)
            previous_dash = False
        elif not previous_dash:
            pieces.append("-")
            previous_dash = True
    return "".join(pieces).strip("-")


def iso_modified(path: Path) -> str:
    return datetime.fromtimestamp(path.stat().st_mtime, tz=timezone.utc).replace(microsecond=0).isoformat()


def artifact(kind: str, path: Path) -> Artifact:
    return Artifact(
        kind=kind,
        path=str(path),
        name=path.name,
        modified_at=iso_modified(path),
    )


def path_has_archive_suffix(path: Path) -> bool:
    lower_name = path.name.lower()
    return any(lower_name.endswith(suffix) for suffix in ARCHIVE_SUFFIXES)


def looks_like_note(path: Path) -> bool:
    lower_name = normalize_name(path.stem)
    if path.suffix.lower() not in NOTE_SUFFIXES:
        return False
    return any(keyword in lower_name for keyword in NOTE_KEYWORDS)


def scan_release_dir(release_dir: Path) -> tuple[list[Artifact], list[Artifact], list[Artifact]]:
    app_bundles: list[Artifact] = []
    archives: list[Artifact] = []
    notes: list[Artifact] = []

    for path in walk_visible_paths(release_dir, max_depth=3):
        if path.is_dir() and path.name.endswith(".app"):
            app_bundles.append(artifact("app_bundle", path))
            continue
        if not path.is_file():
            continue
        if path_has_archive_suffix(path):
            archives.append(artifact("archive", path))
        if looks_like_note(path):
            notes.append(artifact("release_note", path))
    return sort_artifacts(app_bundles), sort_artifacts(archives), sort_artifacts(notes)


def scan_notes_paths(paths: list[Path]) -> list[Artifact]:
    notes: list[Artifact] = []
    seen: set[str] = set()
    for path in paths:
        if path.is_file() and path.suffix.lower() in NOTE_SUFFIXES:
            resolved = str(path.resolve())
            if resolved not in seen:
                seen.add(resolved)
                notes.append(artifact("release_note", path.resolve()))
            continue
        if not path.is_dir():
            continue
        for candidate in walk_visible_paths(path, max_depth=2):
            if candidate.is_file() and looks_like_note(candidate):
                resolved = str(candidate.resolve())
                if resolved not in seen:
                    seen.add(resolved)
                    notes.append(artifact("release_note", candidate.resolve()))
    return sort_artifacts(notes)


def choose_screenshot_root(release_dir: Path, explicit: Path | None) -> Path | None:
    if explicit:
        return explicit
    for child in sorted(release_dir.iterdir()):
        if child.is_dir() and any(hint in child.name.lower() for hint in SCREENSHOT_DIR_HINTS):
            return child.resolve()
    return release_dir.resolve()


def scan_screenshots(root: Path | None) -> list[Artifact]:
    if root is None or not root.exists():
        return []

    screenshots: list[Artifact] = []
    for path in walk_visible_paths(root, max_depth=3):
        if path.is_file() and path.suffix.lower() in SCREENSHOT_SUFFIXES:
            screenshots.append(artifact("screenshot", path))
    return sort_artifacts(screenshots)


def sort_artifacts(items: list[Artifact]) -> list[Artifact]:
    return sorted(items, key=lambda item: (item.modified_at, item.name.lower()), reverse=True)


def newest_modified(items: list[Artifact]) -> datetime | None:
    if not items:
        return None
    timestamps = [datetime.fromisoformat(item.modified_at) for item in items]
    return max(timestamps)


def contains_expected_name(items: list[Artifact], expected_name: str) -> bool:
    expected = normalize_name(expected_name)
    if not expected:
        return True
    return any(expected in normalize_name(item.name) for item in items)


def archive_has_version_token(items: list[Artifact]) -> bool:
    return any(VERSION_PATTERN.search(item.name) for item in items)


def build_doctor_checks(
    release_dir: Path,
    notes_paths: list[Path],
    screenshot_root: Path | None,
    app_bundles: list[Artifact],
    archives: list[Artifact],
    notes: list[Artifact],
    screenshots: list[Artifact],
) -> list[CheckResult]:
    checks = [
        CheckResult(
            key="release_dir",
            label="Release folder",
            status="ready" if release_dir.is_dir() else "blocked",
            detail=str(release_dir),
        ),
        CheckResult(
            key="artifacts",
            label="Discovered build artifacts",
            status="ready" if app_bundles or archives else "warning",
            detail=f"{len(app_bundles)} app bundle(s), {len(archives)} archive(s)",
        ),
        CheckResult(
            key="notes",
            label="Release note search",
            status="ready" if notes else "warning",
            detail=", ".join(str(path) for path in notes_paths) if notes_paths else str(release_dir),
        ),
        CheckResult(
            key="screenshots",
            label="Screenshot search",
            status="ready" if screenshots else "warning",
            detail=str(screenshot_root) if screenshot_root else "No screenshot root resolved",
        ),
    ]
    return checks


def build_audit_report(args: argparse.Namespace) -> AuditReport:
    release_dir = require_existing_path(args.release_dir, label="release directory")
    if not release_dir.is_dir():
        fail(f"release directory not found: {args.release_dir}")

    resolved_notes_paths = [require_existing_path(raw, label="notes path") for raw in args.notes_path]
    screenshot_root = choose_screenshot_root(
        release_dir,
        require_existing_path(args.screenshot_dir, label="screenshot directory") if args.screenshot_dir else None,
    )

    app_bundles, archives, release_notes = scan_release_dir(release_dir)
    if resolved_notes_paths:
        note_map = {item.path: item for item in release_notes}
        for item in scan_notes_paths(resolved_notes_paths):
            note_map[item.path] = item
        release_notes = sort_artifacts(list(note_map.values()))
    screenshots = scan_screenshots(screenshot_root)

    blocking_issues: list[str] = []
    warnings: list[str] = []
    checks: list[CheckResult] = []

    if app_bundles or archives:
        checks.append(CheckResult("artifacts", "Build artifacts", "ready", f"{len(app_bundles)} app bundle(s), {len(archives)} archive(s)"))
    else:
        detail = "No .app bundle or packaged archive was found under the release folder."
        checks.append(CheckResult("artifacts", "Build artifacts", "blocked", detail))
        blocking_issues.append(detail)

    if release_notes:
        checks.append(CheckResult("notes", "Release notes", "ready", f"{len(release_notes)} release note candidate(s) found"))
    else:
        detail = "No release note file was found. Add --notes-path if notes live outside the release folder."
        checks.append(CheckResult("notes", "Release notes", "blocked", detail))
        blocking_issues.append(detail)

    if len(screenshots) >= args.minimum_screenshots:
        checks.append(CheckResult("screenshots", "Screenshots", "ready", f"{len(screenshots)} screenshot(s) found"))
    else:
        detail = (
            f"Expected at least {args.minimum_screenshots} screenshot(s) but found {len(screenshots)}."
        )
        checks.append(CheckResult("screenshots", "Screenshots", "blocked", detail))
        if args.minimum_screenshots > 0:
            blocking_issues.append(detail)

    if archives:
        checks.append(CheckResult("archives", "Packaged archives", "ready", f"{len(archives)} packaged archive(s) found"))
    elif args.require_packaged_archive:
        detail = "No packaged archive was found, but this audit requires one."
        checks.append(CheckResult("archives", "Packaged archives", "blocked", detail))
        blocking_issues.append(detail)
    else:
        detail = "No packaged archive was found yet. This is a warning because --require-packaged-archive was not set."
        checks.append(CheckResult("archives", "Packaged archives", "warning", detail))
        warnings.append(detail)

    if args.expect_app_name:
        artifact_pool = app_bundles + archives
        if contains_expected_name(artifact_pool, args.expect_app_name):
            checks.append(CheckResult("name_match", "Expected app name", "ready", f"Matched {args.expect_app_name} in local artifact names"))
        else:
            detail = f"Expected app name `{args.expect_app_name}` did not appear in any bundle or archive name."
            checks.append(CheckResult("name_match", "Expected app name", "warning", detail))
            warnings.append(detail)

    if archives:
        if archive_has_version_token(archives):
            checks.append(CheckResult("version_token", "Archive naming", "ready", "At least one archive name includes a version-like token"))
        else:
            detail = "Archive names do not show an obvious version token such as 1.2.3."
            checks.append(CheckResult("version_token", "Archive naming", "warning", detail))
            warnings.append(detail)

    newest_artifact = newest_modified(app_bundles + archives)
    newest_note = newest_modified(release_notes)
    newest_screenshot = newest_modified(screenshots)

    if newest_artifact and newest_note and newest_note < newest_artifact:
        detail = "Release notes look older than the newest artifact in the folder."
        checks.append(CheckResult("notes_freshness", "Notes freshness", "warning", detail))
        warnings.append(detail)

    if newest_artifact and newest_screenshot and newest_screenshot < newest_artifact:
        detail = "Screenshots look older than the newest artifact in the folder."
        checks.append(CheckResult("screenshot_freshness", "Screenshot freshness", "warning", detail))
        warnings.append(detail)

    ready_count = sum(1 for item in checks if item.status == "ready")
    blocked_count = sum(1 for item in checks if item.status == "blocked")
    warning_count = sum(1 for item in checks if item.status == "warning")
    summary = f"{ready_count} ready, {blocked_count} blocking, {warning_count} warning"

    next_actions: list[str] = []
    if not release_notes:
        next_actions.append("Add a release note file or pass --notes-path to the correct note location.")
    if args.minimum_screenshots > len(screenshots):
        next_actions.append(
            f"Add {args.minimum_screenshots - len(screenshots)} more screenshot(s), or lower --minimum-screenshots for this lane."
        )
    if args.require_packaged_archive and not archives:
        next_actions.append("Export a packaged archive such as .dmg, .zip, or .pkg into the release folder.")
    if args.expect_app_name and not contains_expected_name(app_bundles + archives, args.expect_app_name):
        next_actions.append("Align bundle or archive names with the expected product name before shipping.")
    if archives and not archive_has_version_token(archives):
        next_actions.append("Rename the packaged archive to include a visible version token.")
    if not next_actions and warnings:
        next_actions.append("Review the warning list and decide whether the packaging lane is still acceptable.")
    if not next_actions and not blocking_issues:
        next_actions.append("Ship from this folder only after a final manual spot check of notes, screenshots, and archive contents.")

    return AuditReport(
        generated_at=utc_now(),
        release_dir=str(release_dir),
        summary=summary,
        checks=checks,
        blocking_issues=blocking_issues,
        warnings=warnings,
        app_bundles=app_bundles,
        archives=archives,
        release_notes=release_notes,
        screenshots=screenshots,
        next_actions=next_actions,
    )


def render_checks_markdown(title: str, checks: list[CheckResult]) -> str:
    lines = [f"## {title}", ""]
    for item in checks:
        lines.append(f"- `{item.status}` {item.label}: {item.detail}")
    if not checks:
        lines.append("- none")
    return "\n".join(lines)


def render_artifacts_markdown(title: str, items: list[Artifact]) -> str:
    lines = [f"## {title}", ""]
    if not items:
        lines.append("- none")
        return "\n".join(lines)

    for item in items:
        lines.append(f"- `{item.name}`")
        lines.append(f"  path: `{item.path}`")
        lines.append(f"  modified: {item.modified_at}")
    return "\n".join(lines)


def render_doctor_markdown(checks: list[CheckResult]) -> str:
    lines = [
        "# Package Hygiene Audit Doctor",
        "",
        render_checks_markdown("Checks", checks),
    ]
    return "\n".join(lines).rstrip() + "\n"


def render_audit_markdown(report: AuditReport) -> str:
    lines = [
        "# Package Hygiene Audit",
        "",
        f"- Generated: {report.generated_at}",
        f"- Release dir: `{report.release_dir}`",
        f"- Summary: {report.summary}",
        "",
        render_checks_markdown("Checks", report.checks),
        "",
        "## Blocking issues",
        "",
    ]

    if report.blocking_issues:
        for item in report.blocking_issues:
            lines.append(f"- {item}")
    else:
        lines.append("- none")

    lines.extend([
        "",
        "## Warnings",
        "",
    ])
    if report.warnings:
        for item in report.warnings:
            lines.append(f"- {item}")
    else:
        lines.append("- none")

    lines.extend([
        "",
        render_artifacts_markdown("App bundles", report.app_bundles),
        "",
        render_artifacts_markdown("Packaged archives", report.archives),
        "",
        render_artifacts_markdown("Release notes", report.release_notes),
        "",
        render_artifacts_markdown("Screenshots", report.screenshots),
        "",
        "## Next actions",
        "",
    ])
    for action in report.next_actions:
        lines.append(f"- {action}")
    return "\n".join(lines).rstrip() + "\n"


def render_audit_prompt(report: AuditReport) -> str:
    lines = [
        "Package Hygiene Audit",
        f"Summary: {report.summary}",
        f"Release dir: {report.release_dir}",
        "",
        "Blocking issues:",
    ]
    if report.blocking_issues:
        lines.extend(f"- {item}" for item in report.blocking_issues)
    else:
        lines.append("- none")

    lines.extend([
        "",
        "Warnings:",
    ])
    if report.warnings:
        lines.extend(f"- {item}" for item in report.warnings)
    else:
        lines.append("- none")

    lines.extend([
        "",
        f"Artifacts: {len(report.app_bundles)} app bundle(s), {len(report.archives)} archive(s), {len(report.release_notes)} note file(s), {len(report.screenshots)} screenshot(s)",
        "",
        "Next actions:",
    ])
    lines.extend(f"- {item}" for item in report.next_actions)
    return "\n".join(lines).rstrip() + "\n"


def main() -> int:
    args = parse_args()
    if args.minimum_screenshots < 0:
        fail("--minimum-screenshots cannot be negative")

    if args.command == "doctor":
        release_dir = require_existing_path(args.release_dir, label="release directory")
        if not release_dir.is_dir():
            fail(f"release directory not found: {args.release_dir}")
        notes_paths = [require_existing_path(raw, label="notes path") for raw in args.notes_path]
        screenshot_root = choose_screenshot_root(
            release_dir,
            require_existing_path(args.screenshot_dir, label="screenshot directory") if args.screenshot_dir else None,
        )
        app_bundles, archives, release_notes = scan_release_dir(release_dir)
        if notes_paths:
            note_map = {item.path: item for item in release_notes}
            for item in scan_notes_paths(notes_paths):
                note_map[item.path] = item
            release_notes = sort_artifacts(list(note_map.values()))
        screenshots = scan_screenshots(screenshot_root)
        checks = build_doctor_checks(release_dir, notes_paths, screenshot_root, app_bundles, archives, release_notes, screenshots)
        if args.format == "json":
            print(json.dumps({"checks": [item.as_dict() for item in checks]}, indent=2))
        else:
            print(render_doctor_markdown(checks), end="")
        return 0

    report = build_audit_report(args)
    if args.format == "json":
        print(json.dumps(report.as_dict(), indent=2))
    elif args.format == "prompt":
        print(render_audit_prompt(report), end="")
    else:
        print(render_audit_markdown(report), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
