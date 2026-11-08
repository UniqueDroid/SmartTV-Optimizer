#!/usr/bin/env bash
# Schritt 2: Neustart + Prüfung nach einem Batch. Bootet der TV nicht sauber, wird der letzte Batch
# automatisch zurückgerollt (sofern ADB erreichbar).
# Aufruf: ./02_reboot_check.sh <TV-IP>     (BOOT_TIMEOUT=300 Sekunden Standard)
source "$(dirname "$0")/lib.sh"
init_device "${1:-}"
LAST="$(cat "$STATE/LAST_BATCH" 2>/dev/null || true)"; RB="$STATE/rollback_${LAST}.sh"
WANT_OFF="$(grep -oE '^en [^ ]+' "$RB" 2>/dev/null | cut -d' ' -f2 || true)"
HDMI_BEFORE="$(hdmi_count)"
TO="${BOOT_TIMEOUT:-300}"

echo "Neustart …"; adb -s "$SERIAL" reboot </dev/null || true; sleep 20
ok=0; t=0
while [ "$t" -lt "$TO" ]; do
  adb connect "$SERIAL" >/dev/null 2>&1 || true
  [ "$(sh_ getprop sys.boot_completed)" = 1 ] && { ok=1; break; }
  sleep 5; t=$((t+5))
done

if [ "$ok" != 1 ]; then
  if [ "$(adb -s "$SERIAL" get-state </dev/null 2>/dev/null)" = device ] && [ -x "$RB" ]; then
    warn "Boot nicht abgeschlossen nach ${TO}s – rolle '$LAST' automatisch zurück."
    "$RB" "$SERIAL"; adb -s "$SERIAL" reboot </dev/null || true
    die "Rollback ausgeführt, TV startet neu. Bitte melden, welcher Batch das war."
  fi
  die "TV nicht per ADB erreichbar. Siehe README → Notfall (Werksreset hebt alle disable-user-Änderungen auf)."
fi
sleep 30   # System zur Ruhe kommen lassen
fail=0
H="$(current_home)"; echo "HOME:  ${H:-<leer>}"
[ -n "$H" ] && [[ ! "$H" =~ ^com\.android\.tv\.settings ]] || { warn "Kein brauchbarer HOME-Launcher!"; fail=1; }
HDMI_AFTER="$(hdmi_count)"; echo "HDMI-Zeilen in tv_input: vorher $HDMI_BEFORE, nachher $HDMI_AFTER"
[ "$HDMI_AFTER" -ge "$HDMI_BEFORE" ] || { warn "HDMI-Eingänge fehlen!"; fail=1; }
EN="$(list_pkgs -e)"
for w in $(grep -iE 'waipu|exaring' "$STATE/LATEST/enabled.txt" 2>/dev/null); do
  grep -qx "$w" <<<"$EN" && echo "waipu.tv aktiv: $w" || { warn "waipu.tv ($w) nicht aktiv!"; fail=1; }
done
DIS="$(list_pkgs -d)"
for p in $WANT_OFF; do grep -qx "$p" <<<"$DIS" || echo "Hinweis: $p hat sich beim Boot selbst wieder aktiviert (harmlos)"; done
# Kein geschütztes Paket darf neu deaktiviert sein
while read -r p; do
  is_hard_protected "$p" && ! grep -qx "$p" "$STATE/LATEST/disabled_ab_werk.txt" && { warn "Geschütztes Paket deaktiviert: $p"; fail=1; }
done <<<"$DIS"
CR="$(sh_ logcat -d -t 3000 | grep -A1 'FATAL EXCEPTION' | grep -oE 'Process: [^,]+' | sort | uniq -c || true)"
[ -n "$CR" ] && { echo "Abstürze seit Boot:"; echo "$CR"; }
echo
if [ "$fail" = 0 ]; then echo "OK – bitte jetzt mit der Fernbedienung testen: waipu.tv, Quellen/HDMI, Lautstärke, Home."
else warn "Prüfung fehlgeschlagen. Rückgängig machen: $RB $SERIAL"; exit 2; fi
