#!/usr/bin/env python3
"""Offline unit tests for safe local Xcode skill imports (synthetic fixtures)."""

import importlib.util
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

SCRIPT = Path(__file__).resolve().parents[1] / "install-apple-xcode-skills.py"
spec = importlib.util.spec_from_file_location("apple_skill_installer", SCRIPT)
installer = importlib.util.module_from_spec(spec)
spec.loader.exec_module(installer)


class AppleXcodeSkillImportTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.export = self.root / "export"
        self.export.mkdir()
        for name in ("swiftui-specialist", "device-interaction"):
            folder = self.export / name
            folder.mkdir()
            (folder / "SKILL.md").write_text(
                f"---\nname: {name}\ndescription: Testskill (not from Apple)\n---\n\n# {name}\n",
                encoding="utf-8",
            )
            (folder / "references").mkdir()
            (folder / "references" / "guide.md").write_text("# Ref\n", encoding="utf-8")
        self.canonical = self.root / ".agents" / "skills"
        self.claude = self.root / ".claude" / "skills"
        self.canonical.mkdir(parents=True)
        self.claude.mkdir(parents=True)
        self.mocks = [
            patch.object(installer, "ROOT", self.root),
            patch.object(installer, "MANIFEST", self.root / ".bbt-local" / "apple-xcode-skills.json"),
            patch.object(installer, "EXPECTED_BASE", (self.canonical, self.claude)),
            patch.object(installer, "local_git_exclude"),
        ]
        for mocked in self.mocks:
            mocked.start()
            self.addCleanup(mocked.stop)

    def test_all_exported_skills_include_references_and_both_agents(self):
        installer.install(self.export, replace=False, dry_run=False)
        for base in (self.canonical, self.claude):
            for name in ("swiftui-specialist", "device-interaction"):
                self.assertTrue((base / name / "SKILL.md").is_file())
                self.assertTrue((base / name / "references" / "guide.md").is_file())
        self.assertEqual(len(installer.load_manifest()["managed"]), 2)

    def test_dry_run_keeps_project_untouched(self):
        installer.install(self.export, replace=False, dry_run=True)
        self.assertFalse((self.canonical / "swiftui-specialist").exists())
        self.assertFalse(installer.MANIFEST.exists())

    def test_refuses_to_overwrite_unmanaged_skill(self):
        (self.canonical / "swiftui-specialist").mkdir()
        local = self.canonical / "swiftui-specialist" / "SKILL.md"
        local.write_text("LOCAL", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "nicht von diesem Import"):
            installer.install(self.export, replace=True, dry_run=False)
        self.assertEqual(local.read_text(encoding="utf-8"), "LOCAL")

    def test_requires_explicit_update_then_updates_both_copies(self):
        installer.install(self.export, replace=False, dry_run=False)
        changed = self.export / "swiftui-specialist" / "references" / "guide.md"
        changed.write_text("# Updated\n", encoding="utf-8")
        with self.assertRaisesRegex(ValueError, "replace-existing"):
            installer.install(self.export, replace=False, dry_run=False)
        installer.install(self.export, replace=True, dry_run=False)
        for base in (self.canonical, self.claude):
            self.assertEqual(
                (base / "swiftui-specialist" / "references" / "guide.md").read_text(
                    encoding="utf-8"
                ),
                "# Updated\n",
            )

    def test_rejects_symlink_in_export(self):
        # Symlinks may be unavailable on locked-down machines.
        outside = self.root / "private.txt"
        outside.write_text("SECRET", encoding="utf-8")
        link = self.export / "device-interaction" / "references" / "private.txt"
        try:
            link.symlink_to(outside)
        except (OSError, NotImplementedError):
            self.skipTest("Symlinks not supported")
        with self.assertRaisesRegex(ValueError, "Symlink"):
            installer.exported_skills(self.export)


if __name__ == "__main__":
    unittest.main()
