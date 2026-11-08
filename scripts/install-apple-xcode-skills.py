#!/usr/bin/env python3
"""Install locally exported Apple Xcode agent skills for BBT-Bit without vendoring them.

The original Xcode skill trees are copied into BOTH agent discovery directories:
  .agents/skills/<exported-name>/  (Codex / project skill convention)
  .claude/skills/<exported-name>/  (Claude Code)
The copies are ignored in this checkout via .git/info/exclude and are never
committed by this tool. Existing BBT skills are never overwritten.

Examples:
    python3 scripts/install-apple-xcode-skills.py --from-xcode
    python3 scripts/install-apple-xcode-skills.py --source ~/Downloads/xcode-skills
    python3 scripts/install-apple-xcode-skills.py --source ~/Downloads/xcode-skills --dry-run
    python3 scripts/install-apple-xcode-skills.py --from-xcode --replace-existing
"""

import argparse
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / ".bbt-local" / "apple-xcode-skills.json"
NAME = re.compile(r"[a-z0-9]+(?:-[a-z0-9]+)*\Z")
EXPECTED_BASE = (ROOT / ".agents" / "skills", ROOT / ".claude" / "skills")


def fail(message: str) -> None:
    raise ValueError(message)


def exported_skills(source: Path) -> dict[str, Path]:
    if not source.is_dir() or source.is_symlink():
        fail(f"Exportordner nicht gefunden oder Symlink: {source}")
    skills: dict[str, Path] = {}
    for folder in sorted(source.iterdir()):
        if not folder.is_dir() or folder.is_symlink():
            continue
        instruction = folder / "SKILL.md"
        if not instruction.is_file() or instruction.is_symlink():
            continue
        name = folder.name
        if not NAME.fullmatch(name) or len(name) > 64:
            fail(f"Ungültiger Skill-Verzeichnisname: {name!r}")
        # Reject any symlink in the subtree. A third-party export must never
        # reach into developer credentials or a sibling Git worktree.
        if any(child.is_symlink() for child in folder.rglob("*")):
            fail(f"Symlink im Skill {name!r}; Import abgebrochen.")
        text = instruction.read_text(encoding="utf-8")
        head = re.match(r"\A---\s*\n(.*?)\n---\s*\n", text, re.DOTALL)
        if not head:
            fail(f"{name}: SKILL.md ohne YAML-Frontmatter")
        parsed = re.search(r"(?m)^name:\s*['\"]?([a-z0-9-]+)['\"]?\s*$", head[1])
        if not parsed or parsed[1] != name:
            fail(f"{name}: Frontmatter-Name entspricht nicht dem Verzeichnis")
        if not re.search(r"(?m)^description:\s*\S", head[1]):
            fail(f"{name}: Skill-Beschreibung fehlt")
        skills[name] = folder
    if not skills:
        fail(f"Keine exportierten SKILL.md-Verzeichnisse in {source}")
    return skills


def digest_tree(folder: Path) -> str:
    h = hashlib.sha256()
    for path in sorted(p for p in folder.rglob("*") if p.is_file()):
        h.update(path.relative_to(folder).as_posix().encode("utf-8"))
        h.update(b"\0")
        h.update(path.read_bytes())
    return h.hexdigest()


def load_manifest() -> dict:
    if not MANIFEST.exists():
        return {"managed": {}}
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    if not isinstance(manifest, dict) or not isinstance(manifest.get("managed"), dict):
        fail(f"Ungültiges lokales Manifest: {MANIFEST}")
    return manifest


def local_git_exclude(names: list[str]) -> None:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--git-path", "info/exclude"],
            cwd=ROOT, check=True, capture_output=True, text=True,
        )
    except (OSError, subprocess.CalledProcessError) as error:
        fail(f"Git-Checkout erforderlich, um Apple-Dateien privat zu halten: {error}")
    exclude = Path(result.stdout.strip())
    if not exclude.is_absolute():
        exclude = ROOT / exclude
    exclude.parent.mkdir(parents=True, exist_ok=True)
    before = exclude.read_text(encoding="utf-8") if exclude.exists() else ""
    entries = [f"/.agents/skills/{name}/" for name in names]
    entries += [f"/.claude/skills/{name}/" for name in names]
    entries.append("/.bbt-local/")
    missing = [line for line in entries if line not in before.splitlines()]
    if missing:
        with exclude.open("a", encoding="utf-8") as file:
            if before and not before.endswith("\n"):
                file.write("\n")
            file.write("# Apple Xcode-Skills: lokaler Export, nicht committen\n")
            file.write("\n".join(missing) + "\n")


def install(source: Path, replace: bool, dry_run: bool, xcode_version=None) -> None:
    skills = exported_skills(source)
    manifest = load_manifest()
    managed = manifest["managed"]
    for base in EXPECTED_BASE:
        if not base.is_dir():
            fail(f"BBT-Bit Skill-Verzeichnis fehlt: {base}")
    # Validate all target collisions BEFORE touching any file.
    for name in skills:
        if any((base / name).exists() for base in EXPECTED_BASE):
            if name not in managed:
                fail(f"{name}: vorhandener, nicht von diesem Import verwalteter Skill. "
                     "Er wird nicht überschrieben.")
            if not replace:
                fail(f"{name}: bereits importiert. Für Xcode-Updates --replace-existing angeben.")
    print(f"Apple-Export: {len(skills)} Skill(s): {', '.join(skills)}")
    if dry_run:
        print("DRY RUN: keine Dateien, Git-Ausschlüsse oder Manifeste geändert.")
        return
    # Set excludes before copying any proprietary skill bytes into the checkout.
    local_git_exclude(list(skills))
    for name, original in skills.items():
        staged: list[tuple[Path, Path]] = []
        backups: list[tuple[Path, Path]] = []
        try:
            for base in EXPECTED_BASE:
                with tempfile.TemporaryDirectory(prefix=".bbt-skill-stage-", dir=base) as stage_dir:
                    staged_dir = Path(stage_dir) / name
                    shutil.copytree(original, staged_dir, symlinks=False)
                    target = base / name
                    if target.exists():
                        backup = base / (".bbt-skill-backup-" + name)
                        if backup.exists():
                            fail(f"Altes Backup vorhanden: {backup}")
                        target.rename(backup)
                        backups.append((backup, target))
                    staged_dir.rename(target)
                    staged.append((target, base))
        except Exception:
            for target, _ in staged:
                if target.exists():
                    shutil.rmtree(target)
            for backup, target in reversed(backups):
                if backup.exists():
                    backup.rename(target)
            raise
        for backup, _ in backups:
            shutil.rmtree(backup)
        managed[name] = digest_tree(original)
        print(f"IMPORTIERT: {name} (Codex und Claude, lokal; nicht im Git-Commit)")
    MANIFEST.parent.mkdir(parents=True, exist_ok=True)
    MANIFEST.write_text(
        json.dumps({"source": "local Xcode export",
                    "xcode_version": xcode_version or "not recorded (supplied export)",
                    "managed": managed},
                   ensure_ascii=False, sort_keys=True, indent=2) + "\n",
        encoding="utf-8",
    )
    print("BBT-Bit-Projekt-Skills unverändert. Apple-Inhalte nur im lokalen Checkout.")


def main() -> int:
    args = argparse.ArgumentParser(description=__doc__)
    src = args.add_mutually_exclusive_group(required=True)
    src.add_argument("--source", type=Path, help="Mit Xcode exportierter Ordner")
    src.add_argument("--from-xcode", action="store_true",
                     help="Xcode 27+ selbst per xcrun agent skills export abfragen")
    args.add_argument("--replace-existing", action="store_true",
                      help="Nur zuvor von diesem Installer verwaltete Skills aktualisieren")
    args.add_argument("--dry-run", action="store_true",
                      help="Import nur prüfen, keine Änderungen")
    options = args.parse_args()
    try:
        if options.from_xcode:
            with tempfile.TemporaryDirectory(prefix="bbt-xcode-export-") as export:
                command = ["xcrun", "agent", "skills", "export", "--output-dir", export]
                print("Exportiere Apple-Skills aus der lokal gewählten Xcode-Version ...")
                subprocess.run(command, check=True)
                version = subprocess.run(
                    ["xcodebuild", "-version"], capture_output=True, text=True, check=True
                ).stdout.strip()
                install(Path(export), options.replace_existing, options.dry_run, version)
        else:
            install(options.source.expanduser(), options.replace_existing, options.dry_run)
        return 0
    except (ValueError, OSError, subprocess.CalledProcessError, UnicodeError) as error:
        print(f"FEHLER: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
