#!/usr/bin/env python3
"""Gegenproben für die getrennte Testkonfiguration und IPA-Verifikation."""

import importlib.util
from pathlib import Path
import plistlib
import struct
import tempfile
import unittest
import zipfile

import yaml


ROOT = Path(__file__).resolve().parents[2]


def load(name, filename):
    spec = importlib.util.spec_from_file_location(name, ROOT / "scripts" / filename)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


prepare = load("sidestore_project", "prepare-sidestore-project.py").prepare
verify = load("sidestore_ipa", "verify-ios-test-ipa.py").verify
SHA = "a" * 40
REF = "feature/beispiel"
RUN = "https://github.com/example/app/actions/runs/1"


def binary(platform=2, encrypted=False):
    commands = struct.pack("<6I", 0x32, 24, platform, 18 << 16, 26 << 16, 0)
    if encrypted:
        commands += struct.pack("<6I", 0x2C, 24, 0, 4096, 1, 0)
    return struct.pack("<8I", 0xFEEDFACF, 0x0100000C, 0, 2, 2 if encrypted else 1, len(commands), 0, 0) + commands


class DevicePackageTest(unittest.TestCase):
    def make_ipa(self, directory, *, platform=2, encrypted=False, extra=None, changes=None, executable=True):
        path = Path(directory) / "test.ipa"
        info = {
            "CFBundleIdentifier": "com.babat.bbtbit", "CFBundleDisplayName": "BBT-Bit",
            "CFBundleExecutable": "BitChord", "CFBundleSupportedPlatforms": ["iPhoneOS"],
            "CFBundleShortVersionString": "1.0.4", "CFBundleVersion": "13",
            "BBTTestDistribution": "SideStore", "BitChordRevision": SHA[:12],
            "BBTTestSourceBranch": REF, "BBTTestRunURL": RUN, "UIBackgroundModes": ["audio"],
        }
        info.update(changes or {})
        with zipfile.ZipFile(path, "w") as archive:
            archive.writestr("Payload/BitChord.app/Info.plist", plistlib.dumps(info))
            if executable:
                archive.writestr("Payload/BitChord.app/BitChord", binary(platform, encrypted))
            for name, data in (extra or {}).items():
                archive.writestr(name, data)
        return path

    def test_device_fixture_proves_structure_only(self):
        with tempfile.TemporaryDirectory() as directory:
            report = verify(self.make_ipa(directory), SHA, REF, RUN)
            self.assertEqual(report["bundle_id"], "com.babat.bbtbit")
            self.assertEqual(report["structure"], "BESTANDEN")
            for stage in ("sidestore_signing", "installation", "update_and_data", "audible_playback"):
                self.assertEqual(report[stage], "NICHT GETESTET")

    def test_simulator_and_encrypted_binaries_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            for options in ({"platform": 7}, {"encrypted": True}, {"executable": False}):
                with self.subTest(options=options), self.assertRaises((ValueError, KeyError)):
                    verify(self.make_ipa(directory, **options), SHA, REF, RUN)

    def test_changed_identity_or_provenance_is_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            for changes in ({"CFBundleIdentifier": "com.other.app"}, {"BitChordRevision": "b" * 12},
                            {"BBTTestSourceBranch": "main"}, {"UIBackgroundModes": []}):
                with self.subTest(changes=changes), self.assertRaises(ValueError):
                    verify(self.make_ipa(directory, changes=changes), SHA, REF, RUN)

    def test_extensions_profiles_and_unsafe_paths_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            for name in ("Payload/BitChord.app/PlugIns/Widget.appex/Info.plist",
                         "Payload/BitChord.app/embedded.mobileprovision", "../escaped"):
                with self.subTest(name=name), self.assertRaises(ValueError):
                    verify(self.make_ipa(directory, extra={name: b"fixture"}), SHA, REF, RUN)

    def test_absent_dylib_is_rejected(self):
        # Ein unvollständig verpacktes Framework muss vor der Geräteinstallation auffallen.
        module = load("ipa_macho", "verify-ios-test-ipa.py")
        name = b"@rpath/Missing.framework/Missing\0"
        size = (24 + len(name) + 7) // 8 * 8
        commands = struct.pack("<6I", 0x32, 24, 2, 18 << 16, 26 << 16, 0)
        commands += struct.pack("<6I", 0xC, size, 24, 0, 0, 0) + name + bytes(size - 24 - len(name))
        macho = struct.pack("<8I", 0xFEEDFACF, 0x0100000C, 0, 2, 2, len(commands), 0, 0) + commands
        self.assertEqual(module.inspect_macho(macho), [name.rstrip(b"\0").decode()])
        with tempfile.TemporaryDirectory() as directory:
            path = self.make_ipa(directory, executable=False, extra={"Payload/BitChord.app/BitChord": macho})
            with self.assertRaises(ValueError):
                verify(path, SHA, REF, RUN)


class ProjectTest(unittest.TestCase):
    def test_free_test_profile_preserves_identity_audio_and_source(self):
        original = (ROOT / "AppleApp/project.yml").read_bytes()
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory) / "project.yml"
            output = Path(directory) / "project.sidestore.yml"
            project.write_bytes(original)
            prepare(project, output, REF, RUN)
            self.assertEqual(project.read_bytes(), original)
            before = yaml.safe_load(original)
            after = yaml.safe_load(output.read_text(encoding="utf-8"))
            app = after["targets"]["BitChord"]
            self.assertNotIn("BitChordWidget", after["targets"])
            self.assertNotIn("entitlements", app)
            self.assertEqual(app["settings"]["base"]["PRODUCT_BUNDLE_IDENTIFIER"], "com.babat.bbtbit")
            self.assertEqual(app["sources"], before["targets"]["BitChord"]["sources"])
            self.assertEqual(app["info"]["properties"]["UIBackgroundModes"], ["audio"])
            self.assertEqual(after["settings"], before["settings"])
            for framework in ("BitChordShared", "NativeCoreFFI"):
                self.assertTrue(any(framework in item.get("framework", "") for item in app["dependencies"]))

    def test_original_project_cannot_be_overwritten(self):
        with tempfile.TemporaryDirectory() as directory:
            project = Path(directory) / "project.yml"
            project.write_bytes((ROOT / "AppleApp/project.yml").read_bytes())
            with self.assertRaises(ValueError):
                prepare(project, project, REF, RUN)

    def test_workflow_limits_credentials_and_automatic_builds(self):
        workflow = yaml.safe_load((ROOT / ".github/workflows/ios-sidestore-test.yml").read_text(encoding="utf-8"))
        self.assertEqual(workflow["permissions"], {"contents": "read"})
        condition = workflow["jobs"]["ipa"]["if"]
        self.assertIn("vars.BBT_IOS_TEST_AUTO_BUILD == 'true'", condition)
        self.assertIn("github.ref_name == vars.BBT_IOS_TEST_BRANCH", condition)
        for step in workflow["jobs"]["ipa"]["steps"]:
            if step.get("uses", "").startswith("actions/checkout@"):
                self.assertFalse(step["with"]["persist-credentials"])
            self.assertNotIn("${{ inputs.source_ref }}", step.get("run", ""))


if __name__ == "__main__":
    unittest.main()
