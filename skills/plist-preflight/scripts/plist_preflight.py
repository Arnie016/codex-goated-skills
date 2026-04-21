#!/usr/bin/env python3
"""Audit macOS Info.plist and entitlement metadata without editing files."""

from __future__ import annotations

import argparse
import json
import plistlib
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any


PRIVACY_KEYS = {
    "NSAppleEventsUsageDescription": "Apple Events automation",
    "NSBluetoothAlwaysUsageDescription": "Bluetooth access",
    "NSBluetoothPeripheralUsageDescription": "Bluetooth peripheral access",
    "NSCameraUsageDescription": "camera access",
    "NSContactsUsageDescription": "contacts access",
    "NSLocationUsageDescription": "location access",
    "NSLocationWhenInUseUsageDescription": "location access",
    "NSMicrophoneUsageDescription": "microphone access",
    "NSPhotoLibraryUsageDescription": "photo library access",
    "NSSpeechRecognitionUsageDescription": "speech recognition",
}

PLACEHOLDER_MARKERS = ("example", "sample", "test", "todo", "changeme", "yourcompany")
SEVERITY_ORDER = {
    "note": 0,
    "warning": 1,
    "blocker": 2,
}


@dataclass
class Finding:
    level: str
    path: str
    message: str

    def as_dict(self) -> dict[str, str]:
        return {"level": self.level, "path": self.path, "message": self.message}


def load_plist(path: Path) -> tuple[dict[str, Any] | None, str | None]:
    try:
        with path.open("rb") as handle:
            data = plistlib.load(handle)
    except Exception as exc:  # plistlib raises several parse/IO exceptions.
        return None, str(exc)
    if not isinstance(data, dict):
        return None, "plist root is not a dictionary"
    return data, None


def relative(path: Path, root: Path) -> str:
    try:
        return str(path.resolve().relative_to(root.resolve()))
    except ValueError:
        return str(path)


def is_blank(value: Any) -> bool:
    return value is None or (isinstance(value, str) and not value.strip())


def has_placeholder(value: Any) -> bool:
    if not isinstance(value, str):
        return False
    if is_build_setting(value):
        return False
    lowered = value.lower()
    return any(marker in lowered for marker in PLACEHOLDER_MARKERS)


def is_build_setting(value: Any) -> bool:
    return isinstance(value, str) and value.strip().startswith("$(") and value.strip().endswith(")")


def audit_info_plist(path: Path, root: Path, expect_menu_bar: bool = False) -> list[Finding]:
    data, error = load_plist(path)
    display_path = relative(path, root)
    findings: list[Finding] = []
    if error or data is None:
        return [Finding("blocker", display_path, f"Could not parse plist: {error}")]

    required_keys = ("CFBundleIdentifier", "CFBundleName")
    for key in required_keys:
        if is_blank(data.get(key)):
            findings.append(Finding("blocker", display_path, f"Missing required {key}."))
        elif has_placeholder(data.get(key)):
            findings.append(Finding("warning", display_path, f"{key} looks like a placeholder: {data.get(key)!r}."))

    bundle_id = data.get("CFBundleIdentifier", "")
    if isinstance(bundle_id, str) and bundle_id:
        if is_build_setting(bundle_id):
            findings.append(Finding("note", display_path, f"Bundle identifier comes from build setting {bundle_id!r}."))
        elif "." not in bundle_id:
            findings.append(Finding("warning", display_path, f"Bundle identifier is not reverse-DNS shaped: {bundle_id!r}."))
        if not is_build_setting(bundle_id) and " " in bundle_id:
            findings.append(Finding("blocker", display_path, f"Bundle identifier contains spaces: {bundle_id!r}."))

    executable = data.get("CFBundleExecutable")
    if is_blank(executable):
        findings.append(Finding("warning", display_path, "Missing CFBundleExecutable; generated projects may fill this, but confirm before release."))

    version = data.get("CFBundleShortVersionString")
    build = data.get("CFBundleVersion")
    if is_blank(version):
        findings.append(Finding("warning", display_path, "Missing CFBundleShortVersionString; release surfaces need a human-readable version."))
    elif has_placeholder(version):
        findings.append(Finding("warning", display_path, f"CFBundleShortVersionString looks like a placeholder: {version!r}."))
    elif is_build_setting(version):
        findings.append(Finding("note", display_path, f"CFBundleShortVersionString comes from build setting {version!r}."))

    if is_blank(build):
        findings.append(Finding("warning", display_path, "Missing CFBundleVersion; release builds need an incrementing build number."))
    elif has_placeholder(build):
        findings.append(Finding("warning", display_path, f"CFBundleVersion looks like a placeholder: {build!r}."))
    elif is_build_setting(build):
        findings.append(Finding("note", display_path, f"CFBundleVersion comes from build setting {build!r}."))

    display_name = data.get("CFBundleDisplayName")
    if is_blank(display_name):
        findings.append(Finding("note", display_path, "CFBundleDisplayName is absent; CFBundleName will be used in Finder and app surfaces."))

    if data.get("LSBackgroundOnly") is True and data.get("LSUIElement") is True:
        findings.append(Finding("warning", display_path, "Both LSBackgroundOnly and LSUIElement are true; most menu-bar apps need only one activation posture."))
    elif data.get("LSUIElement") is True:
        findings.append(Finding("note", display_path, "LSUIElement is true, so this app is configured as an accessory/menu-bar-style app."))
    elif expect_menu_bar:
        findings.append(Finding("warning", display_path, "Expected a menu-bar app, but LSUIElement is not true."))
    elif "MenuBar" in str(data.get("CFBundleName", "")) or "Bar" in str(data.get("CFBundleName", "")):
        findings.append(Finding("warning", display_path, "This looks like a menu-bar app but LSUIElement is not true."))

    present_privacy = [key for key in PRIVACY_KEYS if not is_blank(data.get(key))]
    for key in present_privacy:
        if has_placeholder(data.get(key)):
            findings.append(Finding("warning", display_path, f"{key} contains placeholder wording."))
    if present_privacy:
        readable = ", ".join(PRIVACY_KEYS[key] for key in sorted(present_privacy))
        findings.append(Finding("note", display_path, f"Privacy strings present for: {readable}."))

    if not findings:
        findings.append(Finding("note", display_path, "No plist issues found."))
    return findings


def audit_entitlements(path: Path, root: Path) -> list[Finding]:
    data, error = load_plist(path)
    display_path = relative(path, root)
    findings: list[Finding] = []
    if error or data is None:
        return [Finding("blocker", display_path, f"Could not parse entitlements: {error}")]

    sandbox = data.get("com.apple.security.app-sandbox")
    if sandbox is True:
        findings.append(Finding("note", display_path, "App Sandbox entitlement is enabled."))
    elif sandbox is False:
        findings.append(Finding("warning", display_path, "App Sandbox entitlement is explicitly disabled."))
    else:
        findings.append(Finding("note", display_path, "No App Sandbox entitlement found."))

    network_keys = [
        "com.apple.security.network.client",
        "com.apple.security.network.server",
    ]
    enabled_network = [key for key in network_keys if data.get(key) is True]
    if enabled_network:
        findings.append(Finding("note", display_path, f"Network entitlements enabled: {', '.join(enabled_network)}."))

    automation = data.get("com.apple.security.automation.apple-events")
    if automation is True:
        findings.append(Finding("warning", display_path, "Apple Events automation entitlement is enabled; confirm matching usage text and actual need."))

    file_access = [key for key in data if key.startswith("com.apple.security.files.") and data.get(key) is True]
    if file_access:
        findings.append(Finding("note", display_path, f"File access entitlements enabled: {', '.join(sorted(file_access))}."))

    return findings


def discover_files(target: Path) -> list[Path]:
    if target.is_file():
        return [target]
    patterns = ("Info.plist", "*.entitlements")
    files: list[Path] = []
    for pattern in patterns:
        files.extend(path for path in target.rglob(pattern) if path.is_file())
    return sorted(files)


def audit_file(path: Path, root: Path, expect_menu_bar: bool = False) -> list[Finding]:
    if path.name == "Info.plist":
        return audit_info_plist(path, root, expect_menu_bar=expect_menu_bar)
    if path.suffix == ".entitlements":
        return audit_entitlements(path, root)
    return [Finding("warning", relative(path, root), "File is not Info.plist or an .entitlements file.")]


def render_text(findings: list[Finding]) -> str:
    buckets = {"blocker": [], "warning": [], "note": []}
    for finding in findings:
        buckets.setdefault(finding.level, []).append(finding)

    lines: list[str] = []
    labels = (("blocker", "Blockers"), ("warning", "Warnings"), ("note", "Notes"))
    for level, label in labels:
        lines.append(f"{label}:")
        items = buckets.get(level, [])
        if not items:
            lines.append("  - None")
            continue
        for item in items:
            lines.append(f"  - {item.path}: {item.message}")
    return "\n".join(lines)


def render_markdown(findings: list[Finding]) -> str:
    buckets = {"blocker": [], "warning": [], "note": []}
    for finding in findings:
        buckets.setdefault(finding.level, []).append(finding)

    lines = ["# Plist Preflight", ""]
    for level, label in (("blocker", "Blockers"), ("warning", "Warnings"), ("note", "Notes")):
        lines.append(f"## {label}")
        lines.append("")
        items = buckets.get(level, [])
        if not items:
            lines.append("- None")
        else:
            for item in items:
                lines.append(f"- `{item.path}`: {item.message}")
        lines.append("")
    return "\n".join(lines).rstrip()


def render_findings(findings: list[Finding], output_format: str) -> str:
    if output_format == "json":
        return json.dumps([finding.as_dict() for finding in findings], indent=2)
    if output_format == "markdown":
        return render_markdown(findings)
    return render_text(findings)


def should_fail(findings: list[Finding], fail_on: str) -> bool:
    if fail_on == "never":
        return False
    threshold = SEVERITY_ORDER[fail_on]
    return any(SEVERITY_ORDER.get(finding.level, 0) >= threshold for finding in findings)


def command_scan(args: argparse.Namespace) -> int:
    target = Path(args.target).expanduser().resolve()
    if not target.exists():
        print(f"Target not found: {target}", file=sys.stderr)
        return 2

    files = discover_files(target)
    if not files:
        print(f"No Info.plist or .entitlements files found under {target}", file=sys.stderr)
        return 1

    findings: list[Finding] = []
    for path in files:
        findings.extend(audit_file(path, target if target.is_dir() else target.parent, expect_menu_bar=args.expect_menu_bar))

    print(render_findings(findings, args.format))

    return 1 if should_fail(findings, args.fail_on) else 0


def command_inspect(args: argparse.Namespace) -> int:
    target = Path(args.path).expanduser().resolve()
    if not target.is_file():
        print(f"File not found: {target}", file=sys.stderr)
        return 2
    findings = audit_file(target, target.parent, expect_menu_bar=args.expect_menu_bar)
    print(render_findings(findings, args.format))
    return 1 if should_fail(findings, args.fail_on) else 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="Audit macOS Info.plist and entitlement metadata.")
    subparsers = parser.add_subparsers(dest="command", required=True)

    scan = subparsers.add_parser("scan", help="Scan a file or directory for plist metadata issues.")
    scan.add_argument("target", help="App folder, repo folder, Info.plist, or .entitlements file.")
    scan.add_argument("--format", choices=("text", "json", "markdown"), default="text", help="Output format.")
    scan.add_argument("--fail-on", choices=("blocker", "warning", "note", "never"), default="blocker", help="Minimum finding level that returns exit code 1.")
    scan.add_argument("--expect-menu-bar", action="store_true", help="Warn when Info.plist is not configured with LSUIElement=true.")
    scan.set_defaults(func=command_scan)

    inspect = subparsers.add_parser("inspect", help="Inspect one plist-style file.")
    inspect.add_argument("path", help="Info.plist or .entitlements file.")
    inspect.add_argument("--format", choices=("text", "json", "markdown"), default="text", help="Output format.")
    inspect.add_argument("--fail-on", choices=("blocker", "warning", "note", "never"), default="blocker", help="Minimum finding level that returns exit code 1.")
    inspect.add_argument("--expect-menu-bar", action="store_true", help="Warn when Info.plist is not configured with LSUIElement=true.")
    inspect.set_defaults(func=command_inspect)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    raise SystemExit(main())
