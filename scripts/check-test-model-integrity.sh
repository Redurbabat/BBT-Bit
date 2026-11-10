#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
check_dir="$(mktemp -d "${TMPDIR:-/tmp}/red-bit-model-inspect.XXXXXX")"
trap 'rm -rf "$check_dir"' EXIT
python3 - "$check_dir/check.swift" <<'PY'
from pathlib import Path
import sys
source = Path('AppleApp/Sources/PlaybackSession/AutomixModelStore.swift').read_text()
method = source.split('    nonisolated static func inspectFile(', 1)[1].split('    func verify(', 1)[0]
method = '    static func inspectFile(' + method
checks = r'''
let folder = FileManager.default.temporaryDirectory.appendingPathComponent("red-bit-inspect-\(UUID())")
try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: folder) }
let url = folder.appendingPathComponent("model.bin")
let data = Data("abc".utf8)
try data.write(to: url)
let expected = "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
precondition(Inspector.inspectFile(url, bytes: 3, sha256: expected) == true)
precondition(Inspector.inspectFile(url, bytes: 4, sha256: expected) == false)
precondition(Inspector.inspectFile(url, bytes: 3, sha256: String(repeating: "0", count: 64)) == false)
let unchanged = try Data(contentsOf: url)
precondition(unchanged == data)
precondition(Inspector.inspectFile(folder.appendingPathComponent("missing"), bytes: 3, sha256: expected) == nil)
let files = try FileManager.default.contentsOfDirectory(atPath: folder.path)
precondition(files == ["model.bin"])
print("BESTANDEN: Echter CryptoKit-SHA, Größe, fehlende Datei und falscher Hash ohne Reparatur, Löschung oder Zusatzdateien")
'''
Path(sys.argv[1]).write_text('import Foundation\nimport CryptoKit\nenum Inspector {\n' + method + '\n}\n' + checks)
PY
"${SWIFTC:-swiftc}" "$check_dir/check.swift" -o "$check_dir/check"
"$check_dir/check"
