#!/usr/bin/env python3
"""Validate BBT-Bit's repository conventions without an Apple toolchain."""

import argparse
import json
from pathlib import Path
import re
import subprocess
import sys
import tomllib
from urllib.parse import unquote, urlsplit

import yaml


ROOT = Path(__file__).resolve().parents[1]
DOCS = (
    "AGENTS.md", "CLAUDE.md", "AI_START_HERE.md", "version.md", "AUFGABEN.md",
    "ERLEDIGTE-AUFGABEN.md", "ENTSCHEIDUNGEN.md", "PROBLEME.md", "LUECKEN.md",
    "FREMDCODE.md", "docs/ARCHITEKTUR.md", "docs/DATENREGELN.md", "docs/TESTPLAN.md",
    "docs/DESIGN_SYSTEM.md", "docs/AGENT_WORKFLOW.md", "docs/APPLE_XCODE_SKILLS.md", "docs/RELEASE.md",
)
SKILLS = {
    "swiftui-component-smith", "swiftui-motion-director", "swiftui-idea-lab",
    "swiftui-ux-auditor", "bbt-player", "bbt-streaming", "bbt-audio-engine",
    "bbt-liquid-motion", "bbt-ios-testing", "bbt-release",
}
FRAMEWORKS = {"BitChordShared", "NativeCoreFFI"}
PROJECT = "AppleApp/project.yml"
VERSION = r"[0-9]+\.[0-9]+\.[0-9]+"
VERSION_KEYS = ("MARKETING_VERSION", "CURRENT_PROJECT_VERSION")
HEADING = re.compile(r"^(#{1,6})[ \t]+(.+)$", re.MULTILINE)
INLINE_LINK = re.compile(r"\]\(\s*(?:<([^>\n]+)>|([^\s()]+))\s*(?:\"[^\"\n]*\")?\)")
REFERENCE_LINK = re.compile(r"^ {0,3}\[[^\]\n]+\]:\s*(?:<([^>\n]+)>|(\S+))", re.MULTILINE)


def require(condition, message):
    if not condition:
        raise ValueError(message)


def read(path):
    return (ROOT / path).read_text(encoding="utf-8")


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT).decode("utf-8")


def markdown_content(text):
    """Ignore YAML frontmatter, fenced examples and HTML comments."""
    if text.startswith("---\n"):
        _, _, text = text.split("---\n", 2)
    text = re.sub(r"<!--.*?-->", "", text, flags=re.DOTALL)
    lines = []
    fence = ""
    for line in text.splitlines():
        marker = re.match(r"^ {0,3}(\x60{3,}|~{3,})(.*)$", line)
        if fence:
            if marker and marker[1].startswith(fence) and not marker[2].strip():
                fence = ""
        elif marker:
            fence = marker[1]
        else:
            lines.append(line)
    require(not fence, "unclosed Markdown code fence")
    return "\n".join(lines)


def anchors(content):
    used = set()
    for _, heading in HEADING.findall(content):
        slug = re.sub(r"[^\w -]", "", heading.lower()).replace(" ", "-")
        anchor = slug
        count = 1
        while anchor in used:
            anchor = f"{slug}-{count}"
            count += 1
        used.add(anchor)
    return used


def check_markdown(path):
    content = markdown_content(read(path))
    require(sum(level == "#" for level, _ in HEADING.findall(content)) == 1,
            f"{path}: expected a single H1")
    for pattern in (INLINE_LINK, REFERENCE_LINK):
        for groups in pattern.findall(content):
            url = urlsplit(groups[0] or groups[1])
            if url.scheme or url.netloc:
                continue
            target = (ROOT / path).parent / unquote(url.path) if url.path else ROOT / path
            target = target.resolve()
            require(target.is_relative_to(ROOT) and target.exists(),
                    f"{path}: missing or out-of-repository link {url.geturl()}")
            if url.fragment and target.suffix.lower() == ".md":
                require(unquote(url.fragment) in anchors(markdown_content(read(target))),
                        f"{path}: unknown Markdown anchor {url.geturl()}")


def check_docs_and_skills():
    for path in DOCS:
        check_markdown(path)
    require("@AGENTS.md" in read("CLAUDE.md").splitlines(),
            "CLAUDE.md must import the common rules")
    canonical = {path.parent.name for path in (ROOT / ".agents/skills").glob("*/SKILL.md")}
    wrappers = {path.parent.name for path in (ROOT / ".claude/skills").glob("*/SKILL.md")}
    require(SKILLS <= canonical and canonical == wrappers,
            f"missing or unmatched skills: {sorted((SKILLS - canonical) | (canonical ^ wrappers))}")
    for name in sorted(canonical):
        require(re.fullmatch(r"[a-z0-9]+(?:-[a-z0-9]+)*", name) and len(name) <= 64,
                f"invalid skill name: {name}")
        paths = [f".agents/skills/{name}/SKILL.md", f".claude/skills/{name}/SKILL.md"]
        metadata = []
        for path in paths:
            content = read(path)
            frontmatter = re.match(r"\A---\n(.*?)\n---\n", content, re.DOTALL)
            require(frontmatter, f"{path}: missing YAML frontmatter")
            fields = yaml.safe_load(frontmatter[1])
            require(isinstance(fields, dict) and fields.get("name") == name,
                    f"{path}: name must match the directory")
            description = fields.get("description")
            require(isinstance(description, str) and 0 < len(description.strip()) <= 1024,
                    f"{path}: missing or invalid description")
            metadata.append((name, description))
            check_markdown(path)
        require(metadata[0] == metadata[1], f"{name}: Claude and Codex metadata differ")
        require("## Prüfung" in read(paths[0]).splitlines(), f"{name}: missing test guidance")
        require(f"](../../../{paths[0]})" in read(paths[1]),
                f"{name}: Claude entry must link to the canonical skill")


def version_settings(value, base):
    """Find overrides, including per-target, per-configuration and per-SDK settings."""
    if isinstance(value, dict):
        for key, child in value.items():
            if isinstance(key, str) and key.split("[", 1)[0] in VERSION_KEYS:
                require(value is base and key in VERSION_KEYS,
                        f"{PROJECT}: {key} must be set only under settings.base")
            version_settings(child, base)
    elif isinstance(value, list):
        for child in value:
            version_settings(child, base)


def check_version(project):
    base = project["settings"]["base"]
    version_settings(project, base)
    version, build = (str(base[key]) for key in VERSION_KEYS)
    require(re.fullmatch(VERSION, version) and re.fullmatch(r"[1-9][0-9]*", build),
            f"{PROJECT}: expected MAJOR.MINOR.PATCH and a positive integer build")
    for target in ("BitChord", "BitChordWidget"):
        plist = project["targets"][target]["info"]["properties"]
        for field, setting in zip(("CFBundleShortVersionString", "CFBundleVersion"), VERSION_KEYS):
            require(plist.get(field) == f"$({setting})",
                    f"{PROJECT}: {target}.{field} must use {setting}")

    record = json.loads(read("version.json"))
    require(record.get("version") == version and type(record.get("build")) is int
            and record["build"] == int(build), "version.json does not match XcodeGen")
    status = record.get("status")
    require(status in {"candidate", "published"}, "version.json: invalid status")
    section = re.search(r"^## ([^\n]+)\n(.*?)(?=^## |\Z)", read("version.md"), re.M | re.S)
    require(section and section[1] == f"{version} · Build {build}",
            "version.md: first section does not match XcodeGen")
    require(f"**Status:** \x60{status}\x60" in section[2].splitlines(),
            "version.md and version.json statuses differ")
    if status == "published":
        url = record.get("release_url", "")
        require(re.fullmatch(r"https://github\.com/Redurbabat/BBT-Bit/releases/tag/[^/\s]+", url)
                and url in section[2], "published version needs its GitHub release URL in both files")


def check_boundaries(project):
    app = project["targets"]["BitChord"]
    widget = project["targets"]["BitChordWidget"]
    apple_frameworks = {f"Frameworks/{name}.xcframework" for name in FRAMEWORKS}
    app_frameworks = {item.get("framework") for item in app["dependencies"]}
    require(apple_frameworks <= app_frameworks, "app must link both native XCFrameworks")
    require(any(dep.get("target") == "BitChordWidget" and dep.get("embed") is True
                for dep in app["dependencies"]), "app must embed BitChordWidget")
    require(not widget.get("dependencies"),
            "BitChordWidget must remain independent of app and native targets")
    require(all((item if isinstance(item, str) else item["path"]) in {"Sources/Widget", "Sources/Shared"}
                for item in widget["sources"]),
            "BitChordWidget must use only Widget and Shared sources")

    imports = re.compile(
        r"^[ \t]*(?:@\w+[ \t]+)*import[ \t]+"
        r"(?:(?:typealias|struct|class|enum|protocol|let|var|func)[ \t]+)?(\w+)", re.M,
    )
    for area in ("Widget", "Shared"):
        for path in (ROOT / "AppleApp/Sources" / area).rglob("*.swift"):
            require(not (set(imports.findall(read(path))) & (FRAMEWORKS | {"BitChord"})),
                    f"{path.relative_to(ROOT)}: widget/shared source imports an app dependency")

    shared_edges = set(re.findall(r'project\s*\(\s*"(:[^"]+)"', read("shared/build.gradle.kts")))
    vendor_edges = re.findall(r'project\s*\(\s*"(:[^"]+)"', read("vendor/innertubex/build.gradle.kts"))
    require(shared_edges == {":innertubex"} and not vendor_edges,
            "Gradle boundary must remain :shared → :innertubex")
    settings = read("settings.gradle.kts")
    includes = set(re.findall(r'include\s*\(\s*"(:[^"]+)"', settings))
    require(includes == {":shared", ":innertubex"}
            and re.search(r'project\(":innertubex"\)\.projectDir\s*=\s*file\("vendor/innertubex"\)',
                          settings), "Gradle must include :shared and the vendored :innertubex")

    cargo = tomllib.loads(read("native-core/Cargo.toml"))
    for scope in (cargo, *cargo.get("target", {}).values()):
        for table in ("dependencies", "dev-dependencies", "build-dependencies"):
            for name, dependency in scope.get(table, {}).items():
                if isinstance(dependency, dict) and "path" in dependency:
                    target = (ROOT / "native-core" / dependency["path"]).resolve()
                    require(target.is_relative_to(ROOT / "native-core"),
                            f"Cargo dependency {name} crosses the native-core boundary")


def check_provenance(base, project):
    base = git("rev-parse", "--verify", "--end-of-options", f"{base}^{{commit}}").strip()
    changed = git("diff", "--name-only", "--no-renames", "-z", base, "--").split("\0")
    manifests = ("Cargo.toml", "Cargo.lock", ".gradle.kts", ".versions.toml", "Package.resolved")
    third_party = any(path.endswith(manifests) or path.startswith(("vendor/", "native-core/vendor/"))
                      for path in changed)
    if PROJECT in changed:
        previous = yaml.safe_load(git("show", f"{base}:{PROJECT}"))
        third_party |= previous.get("packages") != project.get("packages")
    require(not third_party or "FREMDCODE.md" in changed,
            "dependency or vendor change requires provenance and license notes in FREMDCODE.md")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--base", help="also require provenance updates for dependency changes since this commit")
    args = parser.parse_args()
    try:
        project = yaml.safe_load(read(PROJECT))
        check_docs_and_skills()
        print("PASS Markdown structure, internal links and skill entry points")
        check_version(project)
        print("PASS version.json, version.md and XcodeGen app/widget version")
        check_boundaries(project)
        print("PASS Xcode, Gradle and Cargo boundaries")
        if args.base:
            check_provenance(args.base, project)
            print("PASS dependency provenance review gate")
    except (OSError, TypeError, ValueError, KeyError, yaml.YAMLError, subprocess.CalledProcessError) as error:
        print(f"FAIL {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
