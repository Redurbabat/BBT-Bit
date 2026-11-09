#!/usr/bin/env python3
"""Prüft eine echte Geräte-IPA vor der noch erforderlichen SideStore-Signierung."""

import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import plistlib
import posixpath
import re
import struct
from typing import NamedTuple
import zipfile


def require(condition, message):
    if not condition:
        raise ValueError(message)


class MachOImage(NamedTuple):
    dependencies: tuple[str, ...]
    rpaths: tuple[str, ...]


def inspect_macho(data, executable=False):
    require(len(data) >= 32, "Mach-O-Header fehlt.")
    magic, cpu, _, kind, commands, command_bytes, _, _ = struct.unpack_from("<8I", data)
    require(magic == 0xFEEDFACF and cpu == 0x0100000C, "Kein dünnes arm64-Gerätebinary.")
    require(not executable or kind == 2, "App-Binary ist nicht ausführbar.")
    require(32 + command_bytes <= len(data) and commands <= 4096, "Ungültige Mach-O-Kommandos.")
    offset = 32
    platform = None
    dependencies = []
    rpaths = []
    for _ in range(commands):
        require(offset + 8 <= 32 + command_bytes, "Abgeschnittenes Mach-O-Kommando.")
        command, size = struct.unpack_from("<2I", data, offset)
        require(size >= 8 and offset + size <= 32 + command_bytes, "Ungültige Kommandolänge.")
        if command == 0x32:
            require(size >= 24, "Ungültige Plattformkennung.")
            platform = struct.unpack_from("<I", data, offset + 8)[0]
        elif command == 0x25:
            platform = 2
        elif command in (0x21, 0x2C):
            require(size >= 20 and struct.unpack_from("<I", data, offset + 16)[0] == 0,
                    "Verschlüsseltes App-Store-Binary wird nicht unterstützt.")
        elif command & 0x7FFFFFFF in (0xC, 0x18, 0x1F, 0x23, 0x1C):
            is_rpath = command & 0x7FFFFFFF == 0x1C
            header_size = 12 if is_rpath else 24
            require(size >= header_size, "Ungültiger Bibliotheksverweis oder Laufzeitpfad.")
            start = struct.unpack_from("<I", data, offset + 8)[0]
            require(header_size <= start < size, "Ungültiger Bibliotheksname oder Laufzeitpfad.")
            text = data[offset + start:offset + size]
            require(b"\0" in text, "Bibliotheksname oder Laufzeitpfad ist nicht abgeschlossen.")
            path = text.split(b"\0", 1)[0].decode("utf-8")
            require(path and "\\" not in path, "Leerer oder ungültiger Bibliothekspfad.")
            (rpaths if is_rpath else dependencies).append(path)
        offset += size
    require(offset == 32 + command_bytes, "Mach-O-Kommandogröße stimmt nicht.")
    require(platform == 2, "Binary gehört nicht zu iPhoneOS; Simulator-Apps sind nicht installierbar.")
    return MachOImage(tuple(dependencies), tuple(rpaths))


def verify(ipa: Path, source_sha: str, source_ref: str, run_url: str):
    require(re.fullmatch(r"[a-f0-9]{40}", source_sha), "Vollständige Quellrevision fehlt.")
    with zipfile.ZipFile(ipa) as archive:
        names = archive.namelist()
        name_set = set(names)
        require(len(names) == len(set(names)), "Doppelte ZIP-Einträge.")
        for name in names:
            path = PurePosixPath(name)
            require(not path.is_absolute() and ".." not in path.parts and "\\" not in name,
                    "Unsicherer ZIP-Pfad.")
            require(not name.endswith(("embedded.mobileprovision", "embedded.provisionprofile")),
                    "Das Testpaket darf kein fremdes Provisioning-Profil enthalten.")
            require(not any(part.endswith(".appex") for part in path.parts),
                    "Die kostenlose Testvariante darf keine App-Erweiterung enthalten.")
        roots = [name for name in names if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", name)]
        require(len(roots) == 1, "Genau eine App unter Payload wird erwartet.")
        app_path = roots[0].removesuffix("Info.plist")
        info = plistlib.loads(archive.read(roots[0]))
        require(info.get("CFBundleIdentifier") == "com.babat.bbtbit", "Bundle-ID verändert; Update wäre unsicher.")
        require(info.get("CFBundleDisplayName") == "RED Bit", "Unerwarteter App-Name.")
        require(info.get("CFBundleSupportedPlatforms") == ["iPhoneOS"], "Kein iPhone-Gerätepaket.")
        require(info.get("BBTTestDistribution") == "SideStore", "SideStore-Testkonfiguration fehlt.")
        require(info.get("BBTTestSourceBranch") == source_ref and info.get("BBTTestRunURL") == run_url,
                "Build-Zuordnung stimmt nicht mit dem Auftrag überein.")
        require(info.get("BitChordRevision") == source_sha[:12], "Eingebettete Quellrevision stimmt nicht.")
        require("audio" in info.get("UIBackgroundModes", []), "Hintergrund-Audio fehlt.")
        executable = info.get("CFBundleExecutable", "")
        require(executable and "/" not in executable and "\\" not in executable, "Ungültiger Programmname.")

        def inspect(name, is_executable=False):
            require(name in name_set, f"Binary fehlt: {name}")
            with archive.open(name) as entry:
                return inspect_macho(entry.read(1024 * 1024), is_executable)

        app_root = app_path.rstrip("/")

        def system_path(path):
            normalized = posixpath.normpath(path)
            return normalized.startswith(("/System/Library/", "/usr/lib/"))

        def local_path(base, relative):
            require(not relative.startswith("/") and "\\" not in relative, "Ungültiger relativer Bibliothekspfad.")
            resolved = posixpath.normpath(base + "/" + relative)
            require(resolved == app_root or resolved.startswith(app_path), "Bibliothekspfad verlässt das App-Paket.")
            return resolved

        def anchored_path(path, loader):
            for token, base in (("@executable_path", app_root), ("@loader_path", posixpath.dirname(loader))):
                if path == token:
                    return base
                if path.startswith(token + "/"):
                    return local_path(base, path[len(token) + 1:])
            return None

        def resolve_dependency(dependency, loader, runpaths):
            if dependency.startswith("@rpath/"):
                relative = dependency.removeprefix("@rpath/")
                require(relative and not relative.startswith("/") and ".." not in PurePosixPath(relative).parts,
                        "Unsicherer Framework-Pfad.")
                candidates = [local_path(base, relative) for base in runpaths]
                for candidate in candidates:
                    if candidate in name_set:
                        return candidate
                # Fehlende Swift-Laufzeitbibliotheken darf iOS selbst bereitstellen.
                if re.fullmatch(r"libswift[A-Za-z0-9_]+\.dylib", relative):
                    return None
                raise ValueError(f"Binary fehlt: {dependency}; Suchpfade: {', '.join(candidates) or 'keine Paket-Laufzeitpfade'}")
            anchored = anchored_path(dependency, loader)
            if anchored is not None:
                require(anchored in name_set, f"Binary fehlt: {anchored}")
                return anchored
            require(system_path(dependency), f"Nicht auflösbarer Bibliotheksverweis: {dependency}")
            return None

        pending = [(app_path + executable, ())]
        inspected = set()
        while pending:
            name, inherited = pending.pop()
            if name in inspected:
                continue
            inspected.add(name)
            image = inspect(name, name == app_path + executable)
            # LC_RPATH gilt für die aktuelle Lade-Kette; @loader_path gehört immer
            # zum Binary, das den Suchpfad deklariert, nicht zur späteren Bibliothek.
            own = [anchored_path(path, name) for path in image.rpaths]
            runpaths = tuple(dict.fromkeys([path for path in own if path is not None] + list(inherited)))
            for dependency in reversed(image.dependencies):
                resolved = resolve_dependency(dependency, name, runpaths)
                if resolved is not None:
                    pending.append((resolved, runpaths))
    with ipa.open("rb") as file:
        digest = hashlib.file_digest(file, "sha256").hexdigest()
    return {
        "ipa": ipa.name, "sha256": digest,
        "bundle_id": info["CFBundleIdentifier"], "version": info["CFBundleShortVersionString"],
        "build": info["CFBundleVersion"], "source_sha": source_sha, "source_ref": source_ref, "run_url": run_url,
        "architecture": "arm64", "platform": "iPhoneOS", "distribution": "unsigned-requires-sidestore-signing",
        "structure": "BESTANDEN", "sidestore_signing": "NICHT GETESTET", "installation": "NICHT GETESTET",
        "update_and_data": "NICHT GETESTET", "audible_playback": "NICHT GETESTET",
        "limitations": ["Kein Widget", "Keine App-Group-Freigabe", "Keine iCloud-Synchronisierung"],
    }


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("ipa", type=Path)
    parser.add_argument("--source-sha", required=True)
    parser.add_argument("--source-ref", required=True)
    parser.add_argument("--run-url", required=True)
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    report = verify(args.ipa, args.source_sha, args.source_ref, args.run_url)
    args.output.write_text(json.dumps(report, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print("IPA-Struktur geprüft. SideStore-Signierung und iPhone-Installation sind NICHT GETESTET.")
