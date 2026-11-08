#!/usr/bin/env bash
# Diagnose: Wer schaltet den Stock-Launcher beim Boot wieder ein? Siehe docs/home-taste-launcher.md
# Aufruf:
#   ./04_diagnose_launcher.sh <TV-IP>                 nur lesen, ändert NICHTS
#   ./04_diagnose_launcher.sh <TV-IP> --reboot-test   deaktiviert tvlauncher (Rollback vorab), startet neu,
#                                                     sammelt Boot-Log; zeigt HOME danach nicht auf einen
#                                                     funktionierenden Launcher, wird tvlauncher wieder aktiviert
# Ergebnis: state/diagnose_<zeit>/  (Zusammenfassung in summary.txt)
source "$(dirname "$0")/lib.sh"
STOCK="com.google.android.tvlauncher"
init_device "${1:-}"
MODE="${2:-}"
O="$STATE/diagnose_$(date +%Y%m%d_%H%M%S)"; mkdir -p "$O"

collect(){ # $1 = Präfix
  local x="$1"
  sh_ getprop ro.build.fingerprint                         > "$O/${x}_fingerprint.txt"
  sh_ dumpsys package "$STOCK"                             > "$O/${x}_dumpsys_tvlauncher.txt"
  grep -E 'User 0:|lastDisabledCaller|enabledComponents|disabledComponents' "$O/${x}_dumpsys_tvlauncher.txt" > "$O/${x}_user0_state.txt" || true
  list_pkgs -d                                             > "$O/${x}_disabled.txt"
  home_handlers                                            > "$O/${x}_home_handlers.txt"
  current_home                                             > "$O/${x}_home_current.txt"
  sh_ settings get secure enabled_accessibility_services   > "$O/${x}_accessibility.txt"
  sh_ logcat -d                                            > "$O/${x}_logcat_main.txt"
  sh_ logcat -b events -d                                  > "$O/${x}_logcat_events.txt"
  grep -iE 'tvlauncher|setEnabledSetting|setApplicationEnabledSetting|COMPONENT_ENABLED|PACKAGE_CHANGED|new state: enabled|Force stopping com\.google\.android\.tvlauncher|setupwraith|tungsten|playtv|PlayTv' \
    "$O/${x}_logcat_main.txt" "$O/${x}_logcat_events.txt" > "$O/${x}_logcat_filter.txt" || true
}

collect vorher
if [ "$MODE" = "--reboot-test" ]; then
  if grep -qx "$STOCK" "$O/vorher_disabled.txt"; then echo "tvlauncher ist schon deaktiviert – teste nur den Neustart."
  else
    RB="$STATE/rollback_launcher.sh"; rb_init "$RB"; rb_add "$RB" "$STOCK"; rb_init "$STATE/rollback_all.sh"; rb_add "$STATE/rollback_all.sh" "$STOCK"
    home_handlers | grep -vE "$STOCK_HOME_RE" | grep -q . || die "Kein Ersatz-Launcher mit HOME-Activity installiert – Test abgebrochen."
    sh_ pm disable-user --user 0 "$STOCK" >/dev/null || true
    list_pkgs -d | grep -qx "$STOCK" || die "Deaktivieren fehlgeschlagen."
    collect nach_disable
  fi
  echo "Neustart …"; adb -s "$SERIAL" reboot </dev/null || true; sleep 20
  t=0; until [ "$(sh_ getprop sys.boot_completed)" = 1 ] || [ "$t" -ge 600 ]; do adb connect "$SERIAL" >/dev/null 2>&1 || true; sleep 5; t=$((t+5)); done
  [ "$(sh_ getprop sys.boot_completed)" = 1 ] || die "Boot nicht fertig nach 600 s – kein automatisches Eingreifen. Rollback: $STATE/rollback_launcher.sh $SERIAL"
  echo "Boot fertig nach ca. $((t+20)) s"; echo "$((t+20))" > "$O/boot_sekunden.txt"
  sleep 60   # späte Boot-Dienste abwarten
  collect nach_boot
  H="$(cat "$O/nach_boot_home_current.txt")"
  if [[ -z "$H" || "$H" =~ ^com\.android\.tv\.settings ]]; then
    sh_ pm enable --user 0 "$STOCK" >/dev/null; echo "HOME war FallbackHome/leer → tvlauncher wieder aktiviert."
  fi
fi

S="$O/summary.txt"
{
  echo "Firmware: $(cat "$O/vorher_fingerprint.txt")"
  echo "Erwartet (andere TPM191E): Philips/PH9M_EA_5599/PH9M_EA_5599:12/STT2.230526.001/4215:user/release-keys"
  for x in vorher nach_disable nach_boot; do
    [ -f "$O/${x}_user0_state.txt" ] || continue
    echo; echo "== $x"
    echo "HOME: $(cat "$O/${x}_home_current.txt")"
    echo "tvlauncher deaktiviert: $(grep -qx "$STOCK" "$O/${x}_disabled.txt" && echo ja || echo NEIN)"
    echo "Anzahl deaktivierte Pakete: $(wc -l < "$O/${x}_disabled.txt")"
    echo "User-0-Zustand (enabled=0 Standard, 1 aktiv eingeschaltet, 2 aus, 3 disabled-user, 4 bis Nutzung):"
    sed 's/^/  /' "$O/${x}_user0_state.txt"
    echo "Bedienungshilfen: $(cat "$O/${x}_accessibility.txt")"
  done
  if [ -f "$O/nach_disable_disabled.txt" ] && [ -f "$O/nach_boot_disabled.txt" ]; then
    echo; echo "== Nach dem Boot wieder eingeschaltet:"
    comm -23 "$O/nach_disable_disabled.txt" "$O/nach_boot_disabled.txt" | sed 's/^/  /'
  fi
  [ -s "$STATE/rollback_events.log" ] && { echo; echo "== Auto-Rollbacks durch 02_reboot_check.sh:"; sed 's/^/  /' "$STATE/rollback_events.log"; }
  echo; echo "== Log-Treffer (Auszug, voll in *_logcat_filter.txt):"
  tail -n 40 "$O/$( [ -f "$O/nach_boot_logcat_filter.txt" ] && echo nach_boot || echo vorher)_logcat_filter.txt" 2>/dev/null | sed 's/^/  /'
} > "$S"
cat "$S"; echo; echo "Alles gespeichert in: $O"
