#!/usr/bin/env bash
# Schritt 1: Einen Batch reversibel deaktivieren (nur pm disable-user --user 0).
# Aufruf: ./01_disable_batch.sh <TV-IP> batches/<batch>.txt      (YES=1 überspringt die Rückfrage)
# Sicherheitsregeln:
#  - ohne Backup kein Start
#  - geschützte Pakete im Batch => ganzer Batch wird abgebrochen (Liste ist dann fehlerhaft)
#  - übersprungen: nicht installiert, bereits (ab Werk) deaktiviert, TvInput-Anbieter, HOME-Handler, PERSISTENT
#  - Rollback-Zeile wird VOR dem Deaktivieren geschrieben
#  - nach jedem Paket wird geprüft, ob der TV noch antwortet; bei Fehler sofort Stopp
source "$(dirname "$0")/lib.sh"
BATCH="${2:?Batch-Datei angeben}"; [ -f "$BATCH" ] || die "Batch $BATCH nicht gefunden"
init_device "${1:-}"
[ -e "$STATE/LATEST/original_packages.txt" ] || die "Kein Backup gefunden – zuerst ./00_backup.sh <TV-IP>"
NAME="$(basename "$BATCH" .txt)"

mapfile -t PKGS < <(grep -vE '^[[:space:]]*(#|$)' "$BATCH" | awk '{print $1}')
[ "${#PKGS[@]}" -gt 0 ] || die "Batch enthält keine aktiven Zeilen"

# --- Sonder-Sperren ---
if [[ "$NAME" == batch4* ]]; then
  H="$(current_home)"; [[ "$H" =~ $STOCK_HOME_RE ]] && die "HOME ist noch der Stock-Launcher ($H). Erst Ersatz-Launcher als Standard."
  EN="$(list_pkgs -e)"; for l in $STOCK_LAUNCHERS; do grep -qx "$l" <<<"$EN" && die "$l ist aktiv – tvrecommendations abschalten würde ihn abstürzen lassen."; done
fi
ALLOW_T=0
if [[ "$NAME" == batch5* ]]; then
  [ "${ALLOW_TUNER:-0}" = "1" ] || die "Tuner-Batch nur mit ALLOW_TUNER=1 (siehe batches/batch5_tuner.txt)"
  ALLOW_T=1
fi

INSTALLED="$(list_pkgs)"; DISABLED="$(list_pkgs -d)"; PROV="$(tvinput_providers)"; HOMES="$(home_handlers)"
TODO=()
for p in "${PKGS[@]}"; do
  [[ "$p" =~ ^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$ ]] || die "Ungültiger Paketname: '$p'"
  if is_hard_protected "$p"; then die "$p ist GESCHÜTZT (whitelist_hard.regex) – Batch-Liste korrigieren"; fi
  if is_tuner "$p" && [ "$ALLOW_T" != 1 ]; then die "$p ist Tuner – nur über batch5 mit ALLOW_TUNER=1"; fi
  if ! grep -qx "$p" <<<"$INSTALLED"; then echo "nicht installiert   $p"; continue; fi
  if grep -qx "$p" <<<"$DISABLED";  then echo "schon deaktiviert   $p (wird nicht angefasst)"; continue; fi
  if grep -qx "$p" <<<"$PROV";      then echo "ÜBERSPRUNGEN        $p (stellt TV-Eingang bereit)"; continue; fi
  if grep -qx "$p" <<<"$HOMES";     then echo "ÜBERSPRUNGEN        $p (HOME-Handler)"; continue; fi
  if is_persistent "$p";            then echo "ÜBERSPRUNGEN        $p (PERSISTENT – Bootrisiko)"; continue; fi
  TODO+=("$p")
done
[ "${#TODO[@]}" -gt 0 ] || { echo "Nichts zu tun."; exit 0; }

echo; echo "Wird deaktiviert (${#TODO[@]}):"; printf '  %s\n' "${TODO[@]}"
if [ "${YES:-0}" != 1 ]; then read -r -p "Fortfahren? Tippe 'ja': " a </dev/tty; [ "$a" = ja ] || die "Abgebrochen."; fi

RB="$STATE/rollback_${NAME}.sh"; ALL="$STATE/rollback_all.sh"; rb_init "$RB"; rb_init "$ALL"
sh_ dumpsys tv_input > "$STATE/vor_${NAME}_tv_input.txt"
echo "$NAME" > "$STATE/LAST_BATCH"
for p in "${TODO[@]}"; do
  rb_add "$RB" "$p"; rb_add "$ALL" "$p"            # erst Rückweg sichern, dann ändern
  sh_ pm disable-user --user 0 "$p" >/dev/null || true
  if list_pkgs -d | grep -qx "$p"; then echo "deaktiviert         $p"
  else die "$p konnte nicht deaktiviert werden – Stopp. (Rollback: $RB)"; fi
  [ "$(sh_ getprop sys.boot_completed)" = 1 ] || die "TV antwortet nicht mehr normal – Stopp. Rollback: $RB $SERIAL"
done
echo; echo "Fertig. Rückweg: $RB $SERIAL"
echo "Jetzt: ./02_reboot_check.sh $SERIAL   (Neustart + automatische Prüfung)"
