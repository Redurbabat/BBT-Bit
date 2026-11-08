#!/usr/bin/env bash
# Selbsttest für scripts/retry-transient.sh: wiederholt nur bei Netzfehlern.
set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
retry="$here/../retry-transient.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
export RETRY_ATTEMPTS=3 RETRY_PAUSE=0
fail() { echo "FEHLER: $1" >&2; exit 1; }

# 1) Zwei Netzfehler, dann Erfolg: Ergebnis 0 nach drei Aufrufen.
cat > "$work/flaky.sh" <<'SH'
#!/usr/bin/env bash
n=$(cat "$1" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$1"
if [ "$n" -lt 3 ]; then echo "Received status code 504 from server: Gateway Time-out"; exit 1; fi
echo ok
SH
chmod +x "$work/flaky.sh"
bash "$retry" "$work/flaky.sh" "$work/count1" >/dev/null || fail "Netzfehler wurde nicht überwunden"
[ "$(cat "$work/count1")" = "3" ] || fail "erwartet 3 Aufrufe, war $(cat "$work/count1")"

# 2) Echter Fehler (kein Netzfehler): sofort abbrechen, Exit-Code bleibt, genau ein Aufruf.
cat > "$work/broken.sh" <<'SH'
#!/usr/bin/env bash
n=$(cat "$1" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$1"
echo "error: cannot find 'foo' in scope"; exit 7
SH
chmod +x "$work/broken.sh"
bash "$retry" "$work/broken.sh" "$work/count2" >/dev/null; code=$?
[ "$code" = "7" ] || fail "Exit-Code 7 erwartet, war $code"
[ "$(cat "$work/count2")" = "1" ] || fail "echter Fehler darf nicht wiederholt werden"

# 3) Dauerhafter Netzfehler: nach allen Versuchen Fehler, drei Aufrufe.
cat > "$work/down.sh" <<'SH'
#!/usr/bin/env bash
n=$(cat "$1" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$1"
echo "Read timed out"; exit 1
SH
chmod +x "$work/down.sh"
bash "$retry" "$work/down.sh" "$work/count3" >/dev/null 2>&1 && fail "dauerhafter Netzfehler muss scheitern"
[ "$(cat "$work/count3")" = "3" ] || fail "erwartet 3 Versuche, war $(cat "$work/count3")"

# 4) Swift-Paketauflösung (Xcode) mit 503: wird wiederholt wie ein anderer Netzfehler.
cat > "$work/spm.sh" <<'SH'
#!/usr/bin/env bash
n=$(cat "$1" 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > "$1"
if [ "$n" -lt 2 ]; then
  echo "failed downloading 'https://example.invalid/Sparkle.zip' which is required by binary target 'Sparkle': badResponseStatusCode(503)"
  exit 74
fi
echo ok
SH
chmod +x "$work/spm.sh"
bash "$retry" "$work/spm.sh" "$work/count4" >/dev/null || fail "SPM-Netzfehler wurde nicht überwunden"
[ "$(cat "$work/count4")" = "2" ] || fail "erwartet 2 Aufrufe für SPM-Fall, war $(cat "$work/count4")"

echo "PASS retry-transient: Netzfehler wiederholt, echte Fehler nicht"
