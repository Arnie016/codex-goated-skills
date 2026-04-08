#!/usr/bin/env python3
"""Audit a repository's launch surface and suggest the right repo shape."""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from collections import defaultdict
from pathlib import Path
from shlex import quote


@dataclass(frozen=True)
class RepoMode:
    name: str
    detail: str


STATIC_WEB_WORKSPACE_FILES = ("index.html", "app.js", "styles.css")

APP_SKILL_ALIASES = {
    "clipboard-studio": "clipboard-studio",
    "flight-scout": "flight-scout",
    "minecraft-skinbar": "minecraft-skin-studio",
    "on-this-day": "on-this-day",
    "on-this-day-bar": "on-this-day-bar",
    "phone-spotter": "find-my-phone-studio",
    "skillbar": "skillbar",
    "telebar": "telebar",
    "trading-archive-bar": "trading-archive",
    "vibe-widget": "vibe-bluetooth",
    "wifi-watchtower": "wifi-watchtower",
}


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


def detect_app_workspace_type(app_dir: Path) -> str | None:
    if (app_dir / "project.yml").is_file():
        return "xcodegen"
    if any(app_dir.glob("*.xcodeproj")):
        return "xcodeproj"
    if (app_dir / "package.json").is_file():
        return "node"
    if all((app_dir / filename).is_file() for filename in STATIC_WEB_WORKSPACE_FILES):
        return "static-web"
    return None


def list_app_workspaces(repo_dir: Path) -> list[dict[str, str]]:
    apps_dir = repo_dir / "apps"
    if not apps_dir.is_dir():
        return []

    workspaces: list[dict[str, str]] = []
    for app_dir in sorted(child for child in apps_dir.iterdir() if child.is_dir()):
        workspace_type = detect_app_workspace_type(app_dir)
        if workspace_type is not None:
            workspaces.append(
                {
                    "name": app_dir.name,
                    "path": str(app_dir),
                    "type": workspace_type,
                }
            )
    return workspaces


def list_skill_names(repo_dir: Path) -> list[str]:
    skills_dir = repo_dir / "skills"
    if not skills_dir.is_dir():
        return []

    return [child.name for child in sorted(skills_dir.iterdir()) if child.is_dir()]


def paired_skill_for_app(app_name: str, skill_names: set[str]) -> tuple[str | None, str]:
    if app_name in skill_names:
        return app_name, "paired"

    alias = APP_SKILL_ALIASES.get(app_name)
    if alias and alias in skill_names:
        return alias, "near-equivalent"

    return None, "unpaired"


def resolve_delegated_runner(script_path: Path, text: str) -> Path | None:
    candidates: list[Path] = []

    match = re.search(r'^\s*DELEGATE="([^"]+)"\s*$', text, re.MULTILINE)
    if match:
        delegate_value = match.group(1).replace("$SCRIPT_DIR", str(script_path.parent))
        delegate_path = Path(delegate_value).expanduser()
        if not delegate_path.is_absolute():
            delegate_path = (script_path.parent / delegate_path).resolve()
        candidates.append(delegate_path)

    exec_match = re.search(r'^\s*exec\s+(?:bash\s+)?"(\$SCRIPT_DIR/[^"]+)"\s+"\$@"\s*$', text, re.MULTILINE)
    if exec_match:
        delegate_path = (script_path.parent / exec_match.group(1).replace("$SCRIPT_DIR/", "")).resolve()
        candidates.append(delegate_path)

    for candidate in candidates:
        if candidate.is_file():
            return candidate
    return None


def runner_commands_from_script(script_path: Path, seen: set[Path] | None = None) -> list[str]:
    resolved_path = script_path.resolve()
    seen = set() if seen is None else seen
    if resolved_path in seen:
        return []
    seen.add(resolved_path)

    text = read_text(script_path)
    commands: list[str] = []
    in_commands = False

    for raw_line in text.splitlines():
        stripped = raw_line.strip()
        if stripped == "Commands:":
            in_commands = True
            continue
        if not in_commands:
            continue
        if stripped.startswith("Examples:"):
            break
        if not stripped:
            continue
        if not re.match(r"^\s{2,}", raw_line):
            if commands:
                break
            continue

        match = re.match(r"^\s{2,}(.+?)(?:\s{2,}|$)", raw_line)
        if not match:
            continue

        command = match.group(1).strip().split("[", 1)[0].strip()
        if command:
            commands.append(command)

    if commands:
        return commands

    delegated = resolve_delegated_runner(script_path, text)
    if delegated is not None:
        return runner_commands_from_script(delegated, seen)

    return commands


def collect_runner_inventory(repo_dir: Path) -> list[dict[str, object]]:
    skills_dir = repo_dir / "skills"
    if not skills_dir.is_dir():
        return []

    inventory: list[dict[str, object]] = []
    for skill_name in list_skill_names(repo_dir):
        script_dir = skills_dir / skill_name / "scripts"
        runner_paths = sorted(path for path in script_dir.glob("run_*.sh") if path.is_file())
        runners: list[dict[str, object]] = []
        for runner_path in runner_paths:
            runner_rel = runner_path.relative_to(repo_dir)
            commands = runner_commands_from_script(runner_path)
            runners.append(
                {
                    "path": str(runner_rel).replace("\\", "/"),
                    "commands": commands,
                }
            )

        inventory.append(
            {
                "skill": skill_name,
                "runner_count": len(runners),
                "runners": runners,
            }
        )

    return inventory


def build_overlap_map(repo_dir: Path, app_workspaces: list[dict[str, str]]) -> dict[str, object]:
    skill_names = set(list_skill_names(repo_dir))
    runner_inventory = collect_runner_inventory(repo_dir)

    app_entries: list[dict[str, object]] = []
    paired_skill_names: set[str] = set()
    command_families: dict[str, set[str]] = defaultdict(set)

    runner_by_skill = {entry["skill"]: entry for entry in runner_inventory}

    for entry in runner_inventory:
        for runner in entry["runners"]:
            for command in runner["commands"]:
                command_families[command].add(runner["path"])

    for app in app_workspaces:
        skill_name, relation = paired_skill_for_app(app["name"], skill_names)
        runner_entry = runner_by_skill.get(skill_name) if skill_name else None
        runner_paths = [runner["path"] for runner in runner_entry["runners"]] if runner_entry else []
        runner_commands = sorted(
            {
                command
                for runner in (runner_entry["runners"] if runner_entry else [])
                for command in runner["commands"]
            }
        )

        if skill_name:
            paired_skill_names.add(skill_name)

        app_entries.append(
            {
                "name": app["name"],
                "type": app["type"],
                "skill": skill_name,
                "relation": relation,
                "runner_paths": runner_paths,
                "commands": runner_commands,
            }
        )

    standalone_skills = sorted(skill_names - paired_skill_names)
    paired_app_count = sum(1 for entry in app_entries if entry["skill"] is not None)
    multi_target_skills = [
        {
            "skill": entry["skill"],
            "runner_paths": [runner["path"] for runner in entry["runners"]],
            "commands": sorted({command for runner in entry["runners"] for command in runner["commands"]}),
        }
        for entry in runner_inventory
        if len(entry["runners"]) > 1
    ]
    multi_target_skills.sort(key=lambda entry: entry["skill"])

    command_families_summary = [
        {
            "command": command,
            "runner_count": len(paths),
            "runner_paths": sorted(set(paths)),
        }
        for command, paths in sorted(command_families.items(), key=lambda item: (-len(item[1]), item[0]))
    ]

    return {
        "app_entries": app_entries,
        "paired_app_count": paired_app_count,
        "paired_skill_count": len(paired_skill_names),
        "standalone_skill_count": len(standalone_skills),
        "standalone_skills": standalone_skills,
        "multi_target_skills": multi_target_skills,
        "command_families": command_families_summary,
    }


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


def readme_surface(repo_dir: Path, mode: RepoMode, app_workspaces: list[dict[str, str]], readme_text: str) -> list[dict[str, object]]:
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


def recommended_commands(repo_dir: Path, mode: RepoMode, app_workspaces: list[dict[str, str]]) -> list[str]:
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
    overlap_map = build_overlap_map(repo_dir, app_workspaces)

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
        install_helpers = sorted(path.name for path in (repo_dir / "scripts").glob("install-*.sh") if path.is_file())
        if install_helpers:
            signals.append(f"install helpers: present ({', '.join(install_helpers)})")
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
        "overlap_map": overlap_map,
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
        for app in report["app_workspaces"]:
            print(f"- {app['name']} ({app['type']})")

    overlap_map = report["overlap_map"]
    print("Overlap map:")
    if overlap_map["app_entries"]:
        print("  App to skill:")
        for entry in overlap_map["app_entries"]:
            if entry["skill"] is None:
                print(f"  - {entry['name']} ({entry['type']}): no paired skill found")
                continue
            relation = entry["relation"]
            runner_note = ""
            if entry["runner_paths"]:
                runner_note = f"; runners: {', '.join(entry['runner_paths'])}"
            if entry["commands"]:
                runner_note += f"; commands: {', '.join(entry['commands'])}"
            print(f"  - {entry['name']} ({entry['type']}): {entry['skill']} [{relation}]{runner_note}")
    else:
        print("  - no app workspaces detected")

    print("  Skill coverage:")
    print(f"  - paired app workspaces: {overlap_map['paired_app_count']}")
    print(f"  - paired skills: {overlap_map['paired_skill_count']}")
    print(f"  - standalone skills: {overlap_map['standalone_skill_count']}")
    if overlap_map["multi_target_skills"]:
        print("  - multi-target skills:")
        for entry in overlap_map["multi_target_skills"]:
            command_note = f" | commands: {', '.join(entry['commands'])}" if entry["commands"] else ""
            print(f"    - {entry['skill']}: {', '.join(entry['runner_paths'])}{command_note}")

    print("  Runner command families:")
    if overlap_map["command_families"]:
        for item in overlap_map["command_families"]:
            print(f"  - {item['command']}: {item['runner_count']} runners")
    else:
        print("  - none detected")

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
