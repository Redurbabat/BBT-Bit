#!/usr/bin/env bash
# Selbsttest für scripts/ensure-metal-toolchain.sh mit nachgebildetem xcrun/xcodebuild.
# Prüft den real beobachteten Fall: Der Download meldet Erfolg, das Werkzeug ist
# aber erst danach aufrufbar.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
script="$here/../ensure-metal-toolchain.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
fail() { echo "FEHLER: $1" >&2; exit 1; }

mkdir -p "$work/bin"
# xcrun: "metal --version" gelingt erst, wenn die Marke existiert. Jeder Aufruf
# wird gezählt, damit der Test auch echte Fehlversuche sieht.
cat > "$work/bin/xcrun" <<'SH'
#!/usr/bin/env bash
[ "${1:-}" = "--kill-cache" ] && exit 0
if [ "${1:-}" = "metal" ]; then
  echo xcrun-metal >> "$METAL_TEST_DIR/xcrun.calls"
  if [ -f "$METAL_TEST_DIR/installed" ]; then echo "metal version 32.0"; exit 0; fi
  echo "error: cannot execute tool 'metal' due to missing Metal Toolchain" >&2
  exit 1
fi
exit 0
SH
# xcodebuild: legt die Marke erst nach METAL_TEST_DELAY Prüfungen an, wie beim
# verzögerten Einhängen des Assets.
cat > "$work/bin/xcodebuild" <<'SH'
#!/usr/bin/env bash
echo download >> "$METAL_TEST_DIR/download.calls"
echo "Done downloading: Metal Toolchain 17A324."
if [ "${METAL_TEST_DELAY:-0}" = "0" ]; then touch "$METAL_TEST_DIR/installed"; fi
exit 0
SH
chmod +x "$work/bin/xcrun" "$work/bin/xcodebuild"
# Kurze, aber von null verschiedene Pause: Die Schleife muss echte Zeit
# vergehen lassen, sonst prüft sie zwölfmal in derselben Millisekunde.
export PATH="$work/bin:$PATH" METAL_TOOLCHAIN_PAUSE=0.05

run_case() {
  export METAL_TEST_DIR="$work/$1"; mkdir -p "$METAL_TEST_DIR"
}

# 1) Toolchain schon vorhanden: kein Download.
run_case ready; touch "$METAL_TEST_DIR/installed"
bash "$script" >/dev/null 2>&1 || fail "vorhandene Toolchain muss sofort gelingen"
[ ! -f "$METAL_TEST_DIR/download.calls" ] || fail "ohne Not wurde heruntergeladen"

# 2) Der beobachtete Fall: Download meldet Erfolg, xcrun findet das Werkzeug
#    erst beim nächsten Versuch. Das alte Skript brach hier ab.
run_case delayed; export METAL_TEST_DELAY=1
( sleep 0.2; touch "$METAL_TEST_DIR/installed" ) &
bash "$script" >/dev/null 2>&1 || fail "verzögert bereitstehende Toolchain muss überwunden werden"
wait
[ -f "$METAL_TEST_DIR/download.calls" ] || fail "fehlende Toolchain muss einen Download auslösen"

# 3) Toolchain bleibt weg: Abbruch mit Fehler, nicht endlos.
run_case missing; export METAL_TEST_DELAY=1; METAL_TOOLCHAIN_ATTEMPTS=3; export METAL_TOOLCHAIN_ATTEMPTS
bash "$script" >/dev/null 2>&1 && fail "dauerhaft fehlende Toolchain muss scheitern"
[ "$(wc -l < "$METAL_TEST_DIR/xcrun.calls")" -ge 4 ] || fail "zu wenige Prüfversuche"

echo "PASS metal-toolchain: Download abgewartet, vorhandene Toolchain nicht erneut geladen"
