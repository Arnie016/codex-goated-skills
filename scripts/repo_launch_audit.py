#!/usr/bin/env python3
"""Audit a repository's launch surface and suggest the right repo shape."""

from __future__ import annotations

import argparse
import json
import sys
from dataclasses import dataclass
from pathlib import Path
from shlex import quote


@dataclass(frozen=True)
class RepoMode:
    name: str
    detail: str


def read_text(path: Path) -> str:
    if path.is_file():
        return path.read_text(encoding="utf-8")
    return ""


def count_children(path: Path) -> int:
    if not path.is_dir():
        return 0
    return sum(1 for child in path.iterdir() if child.is_dir())


def count_files(path: Path, pattern: str = "*") -> int:
    if not path.is_dir():
        return 0
    return sum(1 for child in path.glob(pattern) if child.is_file())


def list_app_workspaces(repo_dir: Path) -> list[str]:
    apps_dir = repo_dir / "apps"
    if not apps_dir.is_dir():
        return []

    workspaces: list[str] = []
    for app_dir in sorted(child for child in apps_dir.iterdir() if child.is_dir()):
        has_project = (app_dir / "project.yml").is_file()
        has_xcodeproj = any(app_dir.glob("*.xcodeproj"))
        has_package_manifest = (app_dir / "package.json").is_file()
        if has_project or has_xcodeproj or has_package_manifest:
            workspaces.append(app_dir.name)
    return workspaces


def detect_root_runner(repo_dir: Path) -> Path | None:
    scripts_dir = repo_dir / "scripts"
    if not scripts_dir.is_dir():
        return None

    candidates = sorted(path for path in scripts_dir.glob("run_*.sh") if path.is_file())
    if len(candidates) == 1:
        return candidates[0]
    return None


def has_any(repo_dir: Path, names: list[str]) -> bool:
    return any((repo_dir / name).exists() for name in names)


def detect_mode(repo_dir: Path, app_workspaces: list[str], readme_text: str) -> RepoMode:
    has_skills = (repo_dir / "skills").is_dir()
    has_collections = (repo_dir / "collections").is_dir()
    has_apps = (repo_dir / "apps").is_dir()
    has_catalog = (repo_dir / "catalog").is_dir()
    root_project = (repo_dir / "project.yml").is_file() or any(repo_dir.glob("*.xcodeproj"))
    package_project = has_any(repo_dir, ["package.json", "pyproject.toml", "Cargo.toml", "go.mod", "uv.lock"])
    template_cues = any(token in readme_text.lower() for token in ("template", "starter", "scaffold"))

    if has_skills and has_collections:
        if has_apps or has_catalog:
            return RepoMode(
                name="multi-project collection",
                detail="skill catalog repo with bundled app workspaces",
            )
        return RepoMode(name="skill catalog repo", detail="installable skills and packs")

    if len(app_workspaces) > 1:
        return RepoMode(name="multi-project collection", detail="bundle of app workspaces")

    if len(app_workspaces) == 1 or root_project:
        return RepoMode(name="single app repo", detail="one app workspace")

    if package_project:
        return RepoMode(name="library / sdk repo", detail="package manifest detected")

    if has_apps:
        return RepoMode(name="multi-project collection", detail="app workspace bundle")

    if template_cues:
        return RepoMode(name="template repo", detail="README suggests scaffolding or reuse")

    return RepoMode(name="template repo", detail="no stronger launch signal detected")


def readme_check(readme_text: str, needle: str) -> bool:
    return needle.lower() in readme_text.lower()


def readme_line_has(readme_text: str, needle: str, exclude: str | None = None) -> bool:
    needle = needle.lower()
    exclude = exclude.lower() if exclude is not None else None
    for raw_line in readme_text.lower().splitlines():
        line = raw_line.strip().strip("`")
        if needle in line and (exclude is None or exclude not in line):
            return True
    return False


def readme_surface(repo_dir: Path, mode: RepoMode, app_workspaces: list[str], readme_text: str) -> list[dict[str, object]]:
    items: list[dict[str, object]] = []

    if not (repo_dir / "README.md").is_file():
        items.append({"label": "README.md", "present": False, "evidence": "missing"})
        return items

    items.append({"label": "README.md", "present": True, "evidence": "present"})

    if mode.name in {"skill catalog repo", "multi-project collection"}:
        has_install_all = (
            readme_check(readme_text, "install-all-skills")
            or readme_check(readme_text, "install --all")
            or readme_line_has(readme_text, "codex-goated install --all")
        )
        has_install_by_name = (
            readme_check(readme_text, "install-skill.sh")
            or readme_check(readme_text, "install by name")
            or readme_line_has(readme_text, "codex-goated install ", exclude="--all")
        )
        items.append(
            {
                "label": "install-all command",
                "present": has_install_all,
                "evidence": "install-all-skills / install --all" if has_install_all else "not found",
            }
        )
        items.append(
            {
                "label": "install-by-name command",
                "present": has_install_by_name,
                "evidence": "install-skill.sh / install by name" if has_install_by_name else "not found",
            }
        )
        items.append(
            {
                "label": "skills table",
                "present": readme_check(readme_text, "| Skill | What it does | Install name |"),
                "evidence": "table header found" if readme_check(readme_text, "| Skill | What it does | Install name |") else "not found",
            }
        )
        if (repo_dir / "apps").is_dir() and app_workspaces:
            items.append(
                {
                    "label": "apps table",
                    "present": readme_check(readme_text, "| App | What it is | Path |"),
                    "evidence": "table header found" if readme_check(readme_text, "| App | What it is | Path |") else "not found",
                }
            )
        items.append(
            {
                "label": "Start Here section",
                "present": readme_check(readme_text, "## Start Here"),
                "evidence": "section header found" if readme_check(readme_text, "## Start Here") else "not found",
            }
        )
    elif mode.name == "single app repo":
        items.append(
            {
                "label": "one-sentence summary",
                "present": bool(readme_text.strip()),
                "evidence": "README has content" if readme_text.strip() else "empty",
            }
        )
        items.append(
            {
                "label": "run or install command",
                "present": readme_check(readme_text, "run") or readme_check(readme_text, "install"),
                "evidence": "run/install wording found" if readme_check(readme_text, "run") or readme_check(readme_text, "install") else "not found",
            }
        )
    elif mode.name == "library / sdk repo":
        items.append(
            {
                "label": "package manager install",
                "present": readme_check(readme_text, "install") or readme_check(readme_text, "npm") or readme_check(readme_text, "uv"),
                "evidence": "package manager wording found" if readme_check(readme_text, "install") or readme_check(readme_text, "npm") or readme_check(readme_text, "uv") else "not found",
            }
        )
        items.append(
            {
                "label": "usage snippet",
                "present": readme_check(readme_text, "usage") or readme_check(readme_text, "example"),
                "evidence": "usage/example wording found" if readme_check(readme_text, "usage") or readme_check(readme_text, "example") else "not found",
            }
        )
    else:
        items.append(
            {
                "label": "scaffold or template copy",
                "present": readme_check(readme_text, "scaffold") or readme_check(readme_text, "template"),
                "evidence": "scaffold/template wording found" if readme_check(readme_text, "scaffold") or readme_check(readme_text, "template") else "not found",
            }
        )

    return items


def required_files(repo_dir: Path, mode: RepoMode) -> list[dict[str, object]]:
    items = [
        {"label": "README.md", "present": (repo_dir / "README.md").is_file()},
        {"label": "LICENSE", "present": (repo_dir / "LICENSE").is_file()},
    ]

    if mode.name in {"skill catalog repo", "multi-project collection"} and (repo_dir / "skills").is_dir():
        items.append({"label": "catalog/index.json", "present": (repo_dir / "catalog/index.json").is_file()})
    return items


def recommended_commands(repo_dir: Path, mode: RepoMode, app_workspaces: list[str]) -> list[str]:
    commands: list[str] = []
    root_runner = detect_root_runner(repo_dir)

    if mode.name in {"skill catalog repo", "multi-project collection"} and (repo_dir / "bin/codex-goated").is_file():
        cli = f"bash {quote(str(repo_dir / 'bin' / 'codex-goated'))}"
        commands.append(f"{cli} doctor")
        commands.append(f"{cli} list")
        commands.append(f"{cli} catalog check")
        commands.append(f"{cli} audit")
        if (repo_dir / "scripts/audit-catalog.sh").is_file():
            commands.append(f"bash {quote(str(repo_dir / 'scripts' / 'audit-catalog.sh'))} --repo-dir {quote(str(repo_dir))}")
        return commands

    if mode.name == "single app repo":
        if root_runner is not None:
            runner = f"bash {quote(str(root_runner))}"
            commands.append(f"{runner} doctor")
            commands.append(f"{runner} inspect")
            commands.append(f"{runner} typecheck")
            commands.append(f"{runner} run")
            return commands

        if (repo_dir / "project.yml").is_file() and any(repo_dir.glob("*.xcodeproj")):
            xcodeproj = next(repo_dir.glob("*.xcodeproj"))
            scheme = xcodeproj.stem
            commands.append(f"cd {quote(str(repo_dir))} && xcodegen generate")
            commands.append(
                f"cd {quote(str(repo_dir))} && xcodebuild -project {quote(xcodeproj.name)} -scheme {quote(scheme)} -destination 'platform=macOS' test"
            )
            return commands

    if mode.name == "library / sdk repo":
        if (repo_dir / "package.json").is_file():
            commands.append(f"cd {quote(str(repo_dir))} && npm test")
            commands.append(f"cd {quote(str(repo_dir))} && npm run build")
        elif (repo_dir / "pyproject.toml").is_file() or (repo_dir / "uv.lock").is_file():
            commands.append(f"cd {quote(str(repo_dir))} && python3 -m pytest")
        return commands

    if app_workspaces:
        commands.append("Inspect the app-specific runner script in scripts/ before editing.")
        return commands

    commands.append("Add one clear start command and keep the README focused on that path.")
    return commands


def build_report(repo_dir: Path) -> dict[str, object]:
    readme_text = read_text(repo_dir / "README.md")
    app_workspaces = list_app_workspaces(repo_dir)
    mode = detect_mode(repo_dir, app_workspaces, readme_text)

    signals: list[str] = []
    if (repo_dir / "skills").is_dir():
        signals.append(f"skills/: present ({count_children(repo_dir / 'skills')} skill packages)")
    if (repo_dir / "collections").is_dir():
        signals.append(f"collections/: present ({count_files(repo_dir / 'collections', '*.txt')} pack files)")
    if (repo_dir / "apps").is_dir():
        signals.append(f"apps/: present ({len(app_workspaces)} app workspaces)")
    if (repo_dir / "catalog").is_dir():
        signals.append("catalog/: present")
    if (repo_dir / "bin" / "codex-goated").is_file():
        signals.append("bin/codex-goated: present")
    if (repo_dir / "scripts").is_dir():
        signals.append(f"scripts/: present ({count_files(repo_dir / 'scripts', '*')} helper scripts)")
    if (repo_dir / "LICENSE").is_file():
        signals.append("LICENSE: present")

    surfaces = readme_surface(repo_dir, mode, app_workspaces, readme_text)
    files = required_files(repo_dir, mode)
    commands = recommended_commands(repo_dir, mode, app_workspaces)

    gaps: list[str] = []
    if not (repo_dir / "README.md").is_file():
        gaps.append("README.md is missing")
    if not (repo_dir / "LICENSE").is_file():
        gaps.append("LICENSE is missing")

    if mode.name in {"skill catalog repo", "multi-project collection"}:
        if (repo_dir / "skills").is_dir() and not (repo_dir / "catalog" / "index.json").is_file():
            gaps.append("catalog/index.json is missing")
        for item in surfaces:
            if not item["present"]:
                gaps.append(f"{item['label']} is missing from README.md")
    elif mode.name == "single app repo":
        for item in surfaces:
            if not item["present"]:
                gaps.append(f"{item['label']} is missing from README.md")
    elif mode.name == "library / sdk repo":
        for item in surfaces:
            if not item["present"]:
                gaps.append(f"{item['label']} is missing from README.md")
    else:
        for item in surfaces:
            if not item["present"]:
                gaps.append(f"{item['label']} is missing from README.md")

    return {
        "repo": str(repo_dir),
        "mode": {"name": mode.name, "detail": mode.detail},
        "signals": signals,
        "app_workspaces": app_workspaces,
        "readme_surface": surfaces,
        "required_files": files,
        "launch_gaps": gaps,
        "recommended_next_commands": commands,
    }


def print_text(report: dict[str, object]) -> None:
    mode = report["mode"]
    print("Repo Launch Audit")
    print(f"Repository: {report['repo']}")
    print(f"Mode: {mode['name']}")
    print(f"Detail: {mode['detail']}")

    print("Signals:")
    for signal in report["signals"]:
        print(f"- {signal}")
    if not report["signals"]:
        print("- none detected")

    if report["app_workspaces"]:
        print("App workspaces:")
        for name in report["app_workspaces"]:
            print(f"- {name}")

    print("README surface:")
    for item in report["readme_surface"]:
        state = "present" if item["present"] else "missing"
        print(f"- {item['label']}: {state}")

    print("Required files:")
    for item in report["required_files"]:
        state = "present" if item["present"] else "missing"
        print(f"- {item['label']}: {state}")

    print("Launch gaps:")
    if report["launch_gaps"]:
        for gap in report["launch_gaps"]:
            print(f"- {gap}")
    else:
        print("- none detected")

    print("Recommended next commands:")
    for command in report["recommended_next_commands"]:
        print(f"- {command}")


def main() -> int:
    parser = argparse.ArgumentParser(description="Audit a repository's launch readiness.")
    parser.add_argument("--repo-dir", default=".", help="Path to the repository to audit")
    parser.add_argument("--format", choices=("text", "json"), default="text", help="Output format")
    parser.add_argument("--strict", action="store_true", help="Exit nonzero when launch gaps are found")
    args = parser.parse_args()

    repo_dir = Path(args.repo_dir).expanduser().resolve()
    if not repo_dir.is_dir():
        print(f"Error: repo not found: {repo_dir}", file=sys.stderr)
        return 1

    report = build_report(repo_dir)

    if args.format == "json":
        print(json.dumps(report, indent=2, ensure_ascii=True))
    else:
        print_text(report)

    if args.strict and report["launch_gaps"]:
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
