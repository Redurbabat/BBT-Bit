"""Counterexamples for the repository checks, without editing project files."""

import importlib.util
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch

import yaml


sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location(
    "repository_checks", Path(__file__).resolve().parents[1] / "check-repository.py",
)
checks = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checks)


class RepositoryChecksTest(unittest.TestCase):
    def setUp(self):
        self.project = yaml.safe_load(checks.read(checks.PROJECT))

    def test_rejects_mismatched_marketing_version(self):
        self.project["settings"]["base"]["MARKETING_VERSION"] = "99.0.0"
        with self.assertRaisesRegex(ValueError, "version.json does not match"):
            checks.check_version(self.project)

    def test_rejects_per_sdk_build_override(self):
        self.project["targets"]["BitChord"]["settings"]["configs"] = {
            "Release": {"CURRENT_PROJECT_VERSION[sdk=iphoneos*]": "999"},
        }
        with self.assertRaisesRegex(ValueError, "must be set only under settings.base"):
            checks.check_version(self.project)

    def test_rejects_widget_plist_drift(self):
        self.project["targets"]["BitChordWidget"]["info"]["properties"]["CFBundleVersion"] = "999"
        with self.assertRaisesRegex(ValueError, "BitChordWidget.CFBundleVersion"):
            checks.check_version(self.project)

    def test_rejects_missing_document_and_anchor(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = Path(temporary)
            source = root / "source.md"
            (root / "guide.md").write_text("# Guide\n\n## First steps\n", encoding="utf-8")
            with patch.object(checks, "ROOT", root):
                for destination, expected in (
                    ("missing.md", "missing or out-of-repository link"),
                    ("guide.md#typo", "unknown Markdown anchor"),
                ):
                    with self.subTest(destination=destination):
                        source.write_text(f"# Source\n\n[Guide]({destination})\n", encoding="utf-8")
                        with self.assertRaisesRegex(ValueError, expected):
                            checks.check_markdown("source.md")

    def test_rejects_missing_skill_installations(self):
        with tempfile.TemporaryDirectory() as temporary:
            with patch.object(checks, "ROOT", Path(temporary)), \
                    patch.object(checks, "DOCS", ()), \
                    patch.object(checks, "read", return_value="@AGENTS.md\n"):
                with self.assertRaisesRegex(ValueError, "missing or unmatched skills"):
                    checks.check_docs_and_skills()

    def test_rejects_widget_import_of_native_core(self):
        read = checks.read

        def read_with_forbidden_import(path):
            if isinstance(path, Path) and path.name == "BitChordWidget.swift":
                return "import SwiftUI\n@testable import NativeCoreFFI\n"
            return read(path)

        with patch.object(checks, "read", side_effect=read_with_forbidden_import):
            with self.assertRaisesRegex(ValueError, "imports an app dependency"):
                checks.check_boundaries(self.project)

    def test_requires_provenance_when_vendor_changes(self):
        with patch.object(checks, "git", side_effect=["base\n", "vendor/innertubex/new.kt\0"]):
            with self.assertRaisesRegex(ValueError, "requires provenance and license notes"):
                checks.check_provenance("HEAD", self.project)
        with patch.object(checks, "git", side_effect=["base\n", "vendor/innertubex/new.kt\0FREMDCODE.md\0"]):
            checks.check_provenance("HEAD", self.project)


if __name__ == "__main__":
    unittest.main()
