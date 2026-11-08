#!/usr/bin/env bash
set -euo pipefail

# Xcode 26 liefert den Metal-Compiler als optionale offizielle Komponente.
# Nur die Entwicklungsumgebung wird vorbereitet; keine Fremdkomponenten in der App.
#
# Nach `-downloadComponent` meldet Xcode "Done downloading", bevor das Asset
# aufrufbar ist: Das DMG liegt dann in /System/Library/AssetsV2, ist aber noch
# nicht eingehängt, und `xcrun` merkt sich außerdem, dass es das Werkzeug zuvor
# nicht gefunden hat. Ein sofortiges `xcrun metal` scheitert deshalb mit genau
# der Meldung, die zum Download geraten hat. Darum hier: Cache leeren und
# wiederholt prüfen, statt beim ersten Fehlschlag abzubrechen.

attempts="${METAL_TOOLCHAIN_ATTEMPTS:-12}"
pause="${METAL_TOOLCHAIN_PAUSE:-10}"

metal_ready() {
  xcrun --kill-cache >/dev/null 2>&1 || true
  xcrun metal --version >/dev/null 2>&1
}

if metal_ready; then
  xcrun metal --version
  exit 0
fi

echo "Metal-Toolchain fehlt; lade die offizielle Apple-Komponente."
# Apple dokumentiert den Namen als "MetalToolchain"; die Fehlermeldung von
# xcrun nennt ihn ebenso.
xcodebuild -downloadComponent MetalToolchain || true

for attempt in $(seq 1 "$attempts"); do
  if metal_ready; then
    xcrun metal --version
    exit 0
  fi
  # Ein zweiter Aufruf nimmt das bereits geladene Asset in Betrieb, statt es
  # erneut zu übertragen.
  if [ "$attempt" -eq 3 ]; then
    xcodebuild -downloadComponent MetalToolchain || true
  fi
  echo "Metal-Toolchain noch nicht aufrufbar (Versuch $attempt von $attempts); erneute Prüfung in ${pause} s"
  sleep "$pause"
done

echo "FEHLER: Metal-Toolchain wurde geladen, ist aber nicht aufrufbar." >&2
ls -la /System/Library/AssetsV2/com_apple_MobileAsset_MetalToolchain 2>/dev/null >&2 || true
xcrun metal --version >&2 || true
exit 1
