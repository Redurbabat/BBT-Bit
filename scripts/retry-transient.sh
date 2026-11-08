#!/usr/bin/env bash
# Führt einen Befehl aus und wiederholt ihn nur, wenn die Ausgabe auf einen
# vorübergehenden Netzfehler beim Herunterladen hinweist (504, Zeitüberschreitung,
# „Could not GET“). Echte Build- und Testfehler brechen sofort ab und werden nie
# weggewiederholt, damit Grün weiter bedeutet: der Code hat seine Tests bestanden.
#
# Aufruf: scripts/retry-transient.sh <Befehl> [Argumente...]
# Umgebung: RETRY_ATTEMPTS (Standard 8), RETRY_PAUSE in Sekunden (Standard 45, wächst je Versuch; zusammen gut 20 Minuten)
set -uo pipefail

attempts="${RETRY_ATTEMPTS:-8}"
pause="${RETRY_PAUSE:-45}"
transient='Received status code 5[0-9][0-9]|Gateway Time-?out|HTTP response code: 5[0-9][0-9]|Read timed out|SocketTimeoutException|Connection (reset|refused)|Could not (GET|HEAD|download)|Downloading from .* failed|UnknownHostException|Premature end of Content-Length'

if [ "$#" -eq 0 ]; then
  echo "Aufruf: $0 <Befehl> [Argumente...]" >&2
  exit 2
fi

log="$(mktemp)"
trap 'rm -f "$log"' EXIT
status=0
for attempt in $(seq 1 "$attempts"); do
  "$@" 2>&1 | tee "$log"
  status="${PIPESTATUS[0]}"
  if [ "$status" -eq 0 ]; then
    exit 0
  fi
  if ! grep -Eq "$transient" "$log"; then
    exit "$status"
  fi
  if [ "$attempt" -lt "$attempts" ]; then
    wait_seconds=$((attempt * pause))
    echo "::warning::Vorübergehender Netzfehler (Versuch $attempt von $attempts); neuer Versuch nach ${wait_seconds} s"
    sleep "$wait_seconds"
  fi
done
echo "::error::Netzfehler blieb nach $attempts Versuchen bestehen; der eigentliche Build oder Test wurde nicht erreicht."
exit "$status"
