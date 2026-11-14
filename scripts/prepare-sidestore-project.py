#!/usr/bin/env python3
"""Erzeugt ausschließlich die temporäre XcodeGen-Konfiguration für kostenlose Gerätetests."""

import argparse
import copy
from pathlib import Path

import yaml


def prepare(project: Path, output: Path, branch: str, run_url: str):
    if project.resolve() == output.resolve() or project.resolve().parent != output.resolve().parent:
        raise ValueError("Die Testkonfiguration muss neben dem Original unter einem anderen Namen liegen.")
    spec = copy.deepcopy(yaml.safe_load(project.read_text(encoding="utf-8")))
    app = spec["targets"]["RedBit"]
    if app["settings"]["base"]["PRODUCT_BUNDLE_IDENTIFIER"] != "com.babat.bbtbit":
        raise ValueError("Unerwartete Bundle-ID; kein automatischer Identitätswechsel.")
    app["supportedDestinations"] = ["iOS"]
    app.pop("entitlements", None)
    app["settings"]["base"]["CODE_SIGN_ENTITLEMENTS"] = ""
    app["dependencies"] = [item for item in app["dependencies"] if item.get("target") != "RedBitWidget"]
    spec["targets"].pop("RedBitWidget", None)
    app["info"]["properties"].update({
        "BBTTestDistribution": "SideStore",
        "BBTTestSourceBranch": branch,
        "BBTTestRunURL": run_url,
        "BBTTestLimitations": "Gerätetest ohne Widget, App-Group-Freigabe und iCloud-Synchronisierung",
    })
    output.write_text(yaml.safe_dump(spec, allow_unicode=True, sort_keys=False), encoding="utf-8")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--project", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--branch", required=True)
    parser.add_argument("--run-url", required=True)
    args = parser.parse_args()
    prepare(args.project, args.output, args.branch, args.run_url)
