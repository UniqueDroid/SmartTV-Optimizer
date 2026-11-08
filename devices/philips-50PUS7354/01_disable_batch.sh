#!/usr/bin/env bash
# Deaktiviert einen Batch reversibel (nur pm disable-user --user 0).
# Aufruf: ./01_disable_batch.sh batches/batch1_telemetrie.txt
# Schreibt jeden deaktivierten Eintrag in rollback.sh.
set -euo pipefail
BATCH="${1:?Batch-Datei angeben}"
INSTALLED=$(adb shell pm list packages | sed 's/^package://' | tr -d '\r')
DISABLED=$(adb shell pm list packages -d | sed 's/^package://' | tr -d '\r')
[ -f rollback.sh ] || { echo '#!/usr/bin/env bash' > rollback.sh; chmod +x rollback.sh; }
grep -vE '^\s*(#|$)' "$BATCH" | awk '{print $1}' | while read -r PKG; do
  if echo "$PKG" | grep -qiEf whitelist.regex; then echo "GESCHÜTZT  $PKG (Whitelist) – übersprungen"; continue; fi
  if ! grep -qx "$PKG" <<<"$INSTALLED"; then echo "FEHLT      $PKG"; continue; fi
  if grep -qx "$PKG" <<<"$DISABLED"; then echo "SCHON AUS  $PKG"; continue; fi
  if adb shell pm disable-user --user 0 "$PKG" | grep -q "disabled"; then
    echo "adb shell pm enable $PKG   # $(date +%F) $(basename "$BATCH")" >> rollback.sh
    echo "DEAKTIV.   $PKG"
  else echo "FEHLER     $PKG"; fi
done
echo; echo "Jetzt TV neu starten (adb reboot) und testen: waipu.tv, Fernbedienung, Lautstärke, WLAN."
