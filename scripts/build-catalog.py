#!/usr/bin/env python3
"""Generate a machine-readable catalog for skills and packs."""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path


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

    frontmatter = {}
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


def parse_pack(pack_file: Path) -> dict[str, object]:
    title = ""
    summary = ""
    skill_ids: list[str] = []
    for raw_line in pack_file.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line:
            continue
        if line.startswith("# title:"):
            title = line.split(":", 1)[1].strip()
            continue
        if line.startswith("# summary:"):
            summary = line.split(":", 1)[1].strip()
            continue
        if line.startswith("#"):
            continue
        skill_ids.append(line)
    return {
        "id": pack_file.stem,
        "title": title,
        "summary": summary,
        "path": str(pack_file.relative_to(pack_file.parents[1])).replace("\\", "/"),
        "skill_count": len(skill_ids),
        "skills": skill_ids,
    }


def build_catalog(repo_dir: Path) -> dict[str, object]:
    skills_dir = repo_dir / "skills"
    collections_dir = repo_dir / "collections"

    packs = [parse_pack(path) for path in sorted(collections_dir.glob("*.txt"))]
    pack_membership: dict[str, list[str]] = {}
    for pack in packs:
        for skill_id in pack["skills"]:
            pack_membership.setdefault(skill_id, []).append(pack["id"])

    skills: list[dict[str, object]] = []
    for skill_dir in sorted(path for path in skills_dir.iterdir() if path.is_dir()):
        skill_file = skill_dir / "SKILL.md"
        openai_file = skill_dir / "agents" / "openai.yaml"
        frontmatter = parse_frontmatter(skill_file) if skill_file.is_file() else {}
        interface = parse_openai_interface(openai_file) if openai_file.is_file() else {}

        skills.append(
            {
                "id": skill_dir.name,
                "display_name": interface.get("display_name", ""),
                "description": frontmatter.get("description", ""),
                "short_description": interface.get("short_description", ""),
                "brand_color": interface.get("brand_color", ""),
                "path": str(skill_dir.relative_to(repo_dir)).replace("\\", "/"),
                "skill_file": str(skill_file.relative_to(repo_dir)).replace("\\", "/"),
                "openai_yaml": str(openai_file.relative_to(repo_dir)).replace("\\", "/"),
                "icon_small": interface.get("icon_small", ""),
                "icon_large": interface.get("icon_large", ""),
                "default_prompt": interface.get("default_prompt", ""),
                "packs": sorted(pack_membership.get(skill_dir.name, [])),
            }
        )

    return {
        "repo": "codex-goated-skills",
        "skill_count": len(skills),
        "pack_count": len(packs),
        "skills": skills,
        "packs": packs,
    }


def render_catalog(catalog: dict[str, object]) -> str:
    return json.dumps(catalog, indent=2, ensure_ascii=True) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Build the repo skill catalog index.")
    parser.add_argument("--repo-dir", default=".", help="Path to the codex-goated-skills repo")
    parser.add_argument("--output", help="Output path for the generated catalog JSON")
    parser.add_argument("--check", action="store_true", help="Fail if the output file is stale")
    args = parser.parse_args()

    repo_dir = Path(args.repo_dir).expanduser().resolve()
    if not (repo_dir / "skills").is_dir():
        print(f"Error: no skills directory found in {repo_dir}", file=sys.stderr)
        return 1

    output_path = Path(args.output).expanduser().resolve() if args.output else repo_dir / "catalog" / "index.json"
    rendered = render_catalog(build_catalog(repo_dir))

    if args.check:
        if not output_path.is_file():
            print(f"Catalog index missing: {output_path}", file=sys.stderr)
            return 1
        existing = output_path.read_text(encoding="utf-8")
        if existing != rendered:
            print(f"Catalog index is stale: {output_path}", file=sys.stderr)
            return 1
        print(f"Catalog index is current: {output_path}")
        return 0

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(rendered, encoding="utf-8")
    print(f"Wrote catalog index to {output_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
