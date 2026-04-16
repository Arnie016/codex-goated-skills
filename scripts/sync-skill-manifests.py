#!/usr/bin/env python3
"""Synchronize manifest-backed skill metadata from repo source files."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

PRIMARY_PACKS = (
    ("launch-and-distribution", "Launch and Distribution"),
    ("productivity-and-workflow", "Productivity and Workflow"),
    ("audience-and-fandom-strategy", "Audience and Fandom Strategy"),
    ("macos-utility-builders", "macOS Utility Builders"),
    ("app-specific-skills", "App-Specific Skills"),
    ("games-and-minecraft", "Games and Minecraft"),
)

PRESERVED_FIELDS = (
    "stars",
    "audience",
    "tags",
    "detail_lines",
    "file_path_hints",
    "system_symbol",
)


def strip_quotes(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {'"', "'"}:
        return value[1:-1]
    return value


def parse_frontmatter(skill_file: Path) -> dict[str, str]:
    text = skill_file.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        return {}

    parts = text.split("---", 2)
    if len(parts) < 3:
        return {}

    frontmatter: dict[str, str] = {}
    for line in parts[1].splitlines():
        if ":" not in line:
            continue
        key, raw_value = line.split(":", 1)
        key = key.strip()
        if key not in {"name", "description"}:
            continue
        frontmatter[key] = strip_quotes(raw_value)
    return frontmatter


def parse_openai_interface(openai_file: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    in_interface = False
    for raw_line in openai_file.read_text(encoding="utf-8").splitlines():
        if raw_line.strip() == "interface:":
            in_interface = True
            continue
        if not in_interface:
            continue
        if raw_line and not raw_line.startswith("  "):
            break
        line = raw_line.strip()
        if not line or ":" not in line:
            continue
        key, raw_value = line.split(":", 1)
        values[key.strip()] = strip_quotes(raw_value)
    return values


def parse_pack(pack_file: Path) -> list[str]:
    skill_ids: list[str] = []
    for raw_line in pack_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#"):
            continue
        skill_ids.append(line)
    return skill_ids


def load_primary_categories(repo_dir: Path) -> dict[str, str]:
    categories: dict[str, str] = {}
    duplicates: dict[str, list[str]] = {}
    for pack_id, title in PRIMARY_PACKS:
        for skill_id in parse_pack(repo_dir / "collections" / f"{pack_id}.txt"):
            if skill_id in categories:
                duplicates.setdefault(skill_id, [categories[skill_id]]).append(title)
                continue
            categories[skill_id] = title

    if duplicates:
        for skill_id, titles in sorted(duplicates.items()):
            joined = ", ".join(titles)
            print(f"Error: {skill_id} belongs to multiple primary categories: {joined}", file=sys.stderr)
        raise SystemExit(1)
    return categories


def load_pack_membership(repo_dir: Path) -> dict[str, list[str]]:
    membership: dict[str, list[str]] = {}
    for pack_file in sorted((repo_dir / "collections").glob("*.txt")):
        for skill_id in parse_pack(pack_file):
            membership.setdefault(skill_id, []).append(pack_file.stem)
    return {skill_id: sorted(pack_ids) for skill_id, pack_ids in membership.items()}


def normalize_asset_path(skill_dir: Path, asset_ref: str) -> str:
    asset_ref = asset_ref.strip()
    if asset_ref.startswith("./"):
        return f"skills/{skill_dir.name}/{asset_ref[2:]}"
    if asset_ref.startswith("skills/"):
        return asset_ref
    return f"skills/{skill_dir.name}/{asset_ref}"


def fallback_asset_path(skill_dir: Path, patterns: tuple[str, ...]) -> str:
    for pattern in patterns:
        matches = sorted((skill_dir / "assets").glob(pattern))
        if matches:
            return str(matches[0].relative_to(skill_dir.parents[1])).replace("\\", "/")
    return ""


def detect_icon_path(skill_dir: Path, interface: dict[str, str], key: str, patterns: tuple[str, ...]) -> str:
    fallback = fallback_asset_path(skill_dir, patterns)
    if fallback:
        return fallback
    if interface.get(key):
        return normalize_asset_path(skill_dir, interface[key])
    return ""


def merge_paths(*path_lists: list[str]) -> list[str]:
    merged: list[str] = []
    seen: set[str] = set()
    for path_list in path_lists:
        for path in path_list:
            if not path or path in seen:
                continue
            merged.append(path)
            seen.add(path)
    return merged


def build_manifest(
    repo_dir: Path,
    skill_dir: Path,
    category: str,
    pack_membership: list[str],
) -> dict[str, object]:
    skill_file = skill_dir / "SKILL.md"
    openai_file = skill_dir / "agents" / "openai.yaml"
    manifest_file = skill_dir / "manifest.json"

    frontmatter = parse_frontmatter(skill_file)
    interface = parse_openai_interface(openai_file)
    existing = json.loads(manifest_file.read_text(encoding="utf-8")) if manifest_file.is_file() else {}

    icon_small = detect_icon_path(skill_dir, interface, "icon_small", ("*small.svg", "icon-small.svg"))
    icon_large = detect_icon_path(skill_dir, interface, "icon_large", ("*large.svg", "icon-large.svg", "preview.svg"))

    docs_paths = merge_paths(
        [
            f"skills/{skill_dir.name}/SKILL.md",
            f"skills/{skill_dir.name}/manifest.json",
            f"skills/{skill_dir.name}/agents/openai.yaml",
            icon_small,
            icon_large,
        ],
        list(existing.get("docs_paths", [])),
    )

    manifest: dict[str, object] = {
        "id": skill_dir.name,
        "name": existing.get("name") or interface.get("display_name") or frontmatter.get("name") or skill_dir.name,
        "category": category,
        "status": existing.get("status", "active"),
        "description": existing.get("description") or frontmatter.get("description") or "",
        "short_description": existing.get("short_description") or interface.get("short_description") or frontmatter.get("description") or "",
        "brand_color": existing.get("brand_color") or interface.get("brand_color") or "",
        "icon_small": icon_small or existing.get("icon_small") or "",
        "icon_large": icon_large or existing.get("icon_large") or "",
        "default_prompt": existing.get("default_prompt") or interface.get("default_prompt") or "",
        "install_command": f"codex-goated install {skill_dir.name}",
        "packs": pack_membership,
        "docs_paths": docs_paths,
    }

    for field in PRESERVED_FIELDS:
        if field in existing:
            manifest[field] = existing[field]

    return manifest


def render_manifest(manifest: dict[str, object]) -> str:
    return json.dumps(manifest, indent=2, ensure_ascii=True) + "\n"


def sync_manifests(repo_dir: Path, check: bool) -> int:
    skill_dirs = sorted(path for path in (repo_dir / "skills").iterdir() if path.is_dir())
    categories = load_primary_categories(repo_dir)
    pack_membership = load_pack_membership(repo_dir)

    missing_categories = [skill_dir.name for skill_dir in skill_dirs if skill_dir.name not in categories]
    if missing_categories:
        for skill_id in missing_categories:
            print(f"Error: {skill_id} is not assigned to any primary category pack", file=sys.stderr)
        return 1

    stale_paths: list[Path] = []
    for skill_dir in skill_dirs:
        manifest_path = skill_dir / "manifest.json"
        rendered = render_manifest(
            build_manifest(
                repo_dir=repo_dir,
                skill_dir=skill_dir,
                category=categories[skill_dir.name],
                pack_membership=pack_membership.get(skill_dir.name, []),
            )
        )

        if check:
            if not manifest_path.is_file() or manifest_path.read_text(encoding="utf-8") != rendered:
                stale_paths.append(manifest_path)
            continue

        manifest_path.write_text(rendered, encoding="utf-8")

    if check:
        if stale_paths:
            for manifest_path in stale_paths:
                reason = "missing" if not manifest_path.is_file() else "stale"
                print(f"{reason.upper()} manifest: {manifest_path}", file=sys.stderr)
            return 1
        print(f"All {len(skill_dirs)} manifest files are current.")
        return 0

    print(f"Synchronized {len(skill_dirs)} manifest files.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="Sync skill manifests from repo metadata.")
    parser.add_argument("--repo-dir", default=".", help="Path to the codex-goated-skills repo")
    parser.add_argument("--check", action="store_true", help="Fail if any manifest is missing or stale")
    args = parser.parse_args()

    repo_dir = Path(args.repo_dir).expanduser().resolve()
    if not (repo_dir / "skills").is_dir():
        print(f"Error: no skills directory found in {repo_dir}", file=sys.stderr)
        return 1

    return sync_manifests(repo_dir, check=args.check)


if __name__ == "__main__":
    raise SystemExit(main())
