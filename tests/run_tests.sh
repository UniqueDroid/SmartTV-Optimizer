#!/usr/bin/env bash
# Offline-Tests mit simulierter adb. Aufruf: tests/run_tests.sh
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; DEV="$ROOT/devices/philips-50PUS7354"
pass=0; failc=0
ok(){ echo "  OK   $1"; pass=$((pass+1)); }
ko(){ echo "  FAIL $1"; failc=$((failc+1)); }
setup(){
  W="$(mktemp -d)"; export FAKE="$W/fake"; mkdir -p "$FAKE" "$W/bin"
  ln -s "$ROOT/tests/fake-adb" "$W/bin/adb"; export PATH="$W/bin:$PATH"
  cp -r "$DEV" "$W/dev"; rm -rf "$W/dev/state"; D="$W/dev"
  echo 1 > "$FAKE/boot"
  cat > "$FAKE/packages.txt" <<P
android
com.android.systemui
com.android.vending
com.google.android.gms
com.google.android.tvlauncher
com.google.android.tvrecommendations
com.google.android.feedback
com.google.android.partnersetup
com.google.android.onetimeinitializer
com.google.android.syncadapters.calendar
com.google.android.youtube.tv
com.google.android.youtube.tvmusic
com.google.android.videos
com.google.android.play.games
com.phorus.playfi.softap
com.mediatek.tvinput
com.netflix.ninja
de.exaring.waipu
org.droidtv.candeebug
org.droidtv.gel
org.droidtv.usagelogger
org.droidtv.demome
org.droidtv.nettvrecommender
org.droidtv.recommendation
org.droidtv.nettv.market
org.droidtv.nettvapps
org.droidtv.sticker
org.droidtv.playtv
org.droidtv.channels
uk.co.freeview.player
P
  echo uk.co.freeview.player > "$FAKE/disabled.txt"
  printf 'com.mediatek.tvinput\norg.droidtv.fastip\n' > "$FAKE/providers.txt"
  printf 'com.google.android.tvlauncher\ncom.android.tv.settings\n' > "$FAKE/homes.txt"
  echo "com.google.android.tvlauncher/.MainActivity" > "$FAKE/home_current"
  : > "$FAKE/persistent.txt"
}
run(){ ( cd "$D" && YES=1 BOOT_TIMEOUT=10 "$@" ) >"$W/out.txt" 2>&1; }
# sleep im Test abkürzen
sleep(){ :; }; export -f sleep

echo "T1 Ohne Backup kein Deaktivieren"; setup
run ./01_disable_batch.sh 1.2.3.4 batches/batch1_telemetrie.txt && ko "lief ohne Backup" || { grep -q "Kein Backup" "$W/out.txt" && ok "verweigert" || ko "falsche Meldung"; }

echo "T2 Backup + Batch 1"; setup
run ./00_backup.sh 1.2.3.4 || ko "backup fehlgeschlagen"
[ -s "$D/state/LATEST/original_packages.txt" ] && ok "Backup angelegt" || ko "kein Backup"
grep -q "en de.exaring.waipu" "$D/state/LATEST/restore_from_backup.sh" && ok "restore enthält aktivierte Pakete" || ko "restore unvollständig"
grep -q "en uk.co.freeview.player" "$D/state/LATEST/restore_from_backup.sh" && ko "restore würde Werks-Deaktiviertes einschalten" || ok "Werks-Deaktiviertes bleibt aus"
run ./01_disable_batch.sh 1.2.3.4 batches/batch1_telemetrie.txt; cat "$W/out.txt" | sed 's/^/      /' | tail -12
n=$(grep -c . "$FAKE/disabled.txt"); [ "$n" = 9 ] && ok "8 Pakete deaktiviert (+1 ab Werk)" || ko "deaktiviert: $n (stdin-Bug?)"
[ "$(grep -c '^en ' "$D/state/rollback_batch1_telemetrie.sh")" = 8 ] && ok "Rollback hat 8 Einträge" || ko "Rollback unvollständig"

echo "T3 Rollback stellt Ausgangszustand her"
( "$D/state/rollback_batch1_telemetrie.sh" 1.2.3.4 ) >/dev/null 2>&1
[ "$(cat "$FAKE/disabled.txt")" = "uk.co.freeview.player" ] && ok "nur Werkszustand übrig" || ko "Rest: $(tr '\n' ' ' < "$FAKE/disabled.txt")"

echo "T4 Geschütztes Paket im Batch bricht ganzen Batch ab"; setup; run ./00_backup.sh 1.2.3.4
printf 'org.droidtv.gel\ncom.google.android.gms\n' > "$W/x.txt"
run ./01_disable_batch.sh 1.2.3.4 "$W/x.txt"; grep -q GESCHÜTZT "$W/out.txt" && ! grep -qx org.droidtv.gel "$FAKE/disabled.txt" && ok "abgebrochen, nichts geändert" || ko "nicht abgebrochen"
for p in com.google.android.tvlauncher com.google.android.apps.tv.launcherx de.exaring.waipu com.netflix.ninja com.google.android.youtube.tv org.droidtv.channels com.mediatek.tvinput com.android.vending com.google.android.leanbackime org.droidtv.eum org.droidtv.fastip org.droidtv.philipstvdrawer com.google.android.apps.mediashell org.droidtv.oad tv.twitch.android.app com.disney.disneyplus com.amazon.amazonvideo.livingroom org.droidtv.nettv_launcherapp com.google.android.tungsten.setupwraith org.droidtv.tvsystemui; do
  grep -qiEf "$D/whitelist_hard.regex" <<<"$p" || ko "nicht geschützt: $p"; done; ok "Whitelist-Stichproben geprüft"
for f in "$D"/batches/*.txt; do grep -vE '^[[:space:]]*(#|$)' "$f" | awk '{print $1}' | while read -r p; do grep -qiEf "$D/whitelist_hard.regex" <<<"$p" && echo "KOLLISION $p in $f"; done; done > "$W/coll"; [ -s "$W/coll" ] && ko "$(cat "$W/coll")" || ok "kein Batch-Paket kollidiert mit Whitelist"

echo "T5 Tuner nur mit ALLOW_TUNER=1"; setup; run ./00_backup.sh 1.2.3.4
run ./01_disable_batch.sh 1.2.3.4 batches/batch5_tuner.txt; grep -qx org.droidtv.playtv "$FAKE/disabled.txt" && ko "Tuner ohne Freigabe aus" || ok "ohne Freigabe verweigert"
echo org.droidtv.playtv > "$W/y.txt"; run ./01_disable_batch.sh 1.2.3.4 "$W/y.txt"; grep -qx org.droidtv.playtv "$FAKE/disabled.txt" && ko "Tuner über anderen Batch aus" || ok "Tuner in anderem Batch verweigert"
echo org.droidtv.playtv > "$W/batch5_test.txt"; ( cd "$D" && YES=1 ALLOW_TUNER=1 ./01_disable_batch.sh 1.2.3.4 "$W/batch5_test.txt" ) >/dev/null 2>&1; grep -qx org.droidtv.playtv "$FAKE/disabled.txt" && ok "mit Freigabe möglich" || ko "mit Freigabe nicht möglich"
run ./01_disable_batch.sh 1.2.3.4 batches/batch5_tuner.txt; grep -q "keine aktiven Zeilen" "$W/out.txt" && ok "Repo-Batch 5 ist auskommentiert" || ko "Batch 5 enthält aktive Zeilen"

echo "T6 Batch 4 gesperrt solange Stock-Launcher aktiv"; setup; run ./00_backup.sh 1.2.3.4
run ./01_disable_batch.sh 1.2.3.4 batches/batch4_nur_mit_ersatzlauncher.txt; grep -qx com.google.android.tvrecommendations "$FAKE/disabled.txt" && ko "Batch 4 lief" || ok "verweigert"

echo "T7 PERSISTENT / TvInput / HOME werden übersprungen"; setup; run ./00_backup.sh 1.2.3.4
echo org.droidtv.gel > "$FAKE/persistent.txt"; echo org.droidtv.candeebug >> "$FAKE/providers.txt"; echo org.droidtv.demome >> "$FAKE/homes.txt"
run ./01_disable_batch.sh 1.2.3.4 batches/batch1_telemetrie.txt
for p in org.droidtv.gel org.droidtv.candeebug org.droidtv.demome; do grep -qx $p "$FAKE/disabled.txt" && ko "$p deaktiviert" || ok "$p übersprungen"; done

echo "T8 Fehlgeschlagenes Deaktivieren stoppt, Rollback-Zeile existiert"; setup; run ./00_backup.sh 1.2.3.4
echo org.droidtv.gel > "$FAKE/refuse.txt"; run ./01_disable_batch.sh 1.2.3.4 batches/batch1_telemetrie.txt
grep -q "konnte nicht deaktiviert" "$W/out.txt" && ok "Stopp bei Fehler" || ko "kein Stopp"
grep -qx org.droidtv.usagelogger "$FAKE/disabled.txt" && ko "lief nach Fehler weiter" || ok "nachfolgende Pakete unangetastet"

echo "T9 Bootschleife nach Neustart → automatischer Rollback"; setup; run ./00_backup.sh 1.2.3.4
run ./01_disable_batch.sh 1.2.3.4 batches/batch2_promo.txt; touch "$FAKE/bootloop_after_reboot"
run ./02_reboot_check.sh 1.2.3.4; grep -q "Rollback ausgeführt" "$W/out.txt" && ok "Rollback ausgelöst" || { ko "kein Rollback"; tail -5 "$W/out.txt"; }
grep -qx org.droidtv.nettv.market "$FAKE/disabled.txt" && ko "Batch nicht zurückgerollt" || ok "Batch zurückgerollt"
grep -q AUTO-ROLLBACK "$D/state/rollback_events.log" && ok "Auto-Rollback protokolliert" || ko "nicht protokolliert"

echo "T10 Normaler Neustart-Check"; setup; run ./00_backup.sh 1.2.3.4; run ./01_disable_batch.sh 1.2.3.4 batches/batch1_telemetrie.txt
run ./02_reboot_check.sh 1.2.3.4; grep -q "^OK" "$W/out.txt" && ok "Check OK" || { ko "Check fehlgeschlagen"; tail -8 "$W/out.txt"; }

echo "T12 Launcher-Wechsel ohne HOME-fähigen Ersatz wird verweigert"; setup; run ./00_backup.sh 1.2.3.4
echo com.spocky.projengmenu >> "$FAKE/packages.txt"
run ./03_launcher_wechsel.sh 1.2.3.4; grep -qx com.google.android.tvlauncher "$FAKE/disabled.txt" && ko "Stock-Launcher aus ohne HOME-Ersatz" || ok "verweigert"
echo "T13 Launcher-Wechsel mit Projectivy"; echo com.spocky.projengmenu >> "$FAKE/homes.txt"
run ./03_launcher_wechsel.sh 1.2.3.4; grep -q "HOME jetzt: com.spocky.projengmenu" "$W/out.txt" && ok "HOME = Projectivy" || { ko "HOME falsch"; tail -3 "$W/out.txt"; }
grep -q "en com.google.android.tvlauncher" "$D/state/rollback_launcher.sh" && ok "Rollback vorhanden" || ko "kein Rollback"
run ./02_reboot_check.sh 1.2.3.4; grep -q "^OK" "$W/out.txt" && ok "Neustart-Check akzeptiert deaktivierten Stock-Launcher" || { ko "Check schlägt fehl"; tail -5 "$W/out.txt"; }
run ./01_disable_batch.sh 1.2.3.4 batches/batch4_nur_mit_ersatzlauncher.txt; grep -qx com.google.android.tvrecommendations "$FAKE/disabled.txt" && ok "Batch 4 jetzt erlaubt" || ko "Batch 4 weiter gesperrt"
( "$D/state/rollback_launcher.sh" 1.2.3.4 ) >/dev/null 2>&1; grep -qx com.google.android.tvlauncher "$FAKE/disabled.txt" && ko "Rollback wirkungslos" || ok "Rollback stellt Stock-Launcher her"
echo "T14 Selbstschutz: HOME landet nicht beim Ersatz → sofort zurück"; setup; run ./00_backup.sh 1.2.3.4
echo com.spocky.projengmenu >> "$FAKE/packages.txt"; echo com.spocky.projengmenu >> "$FAKE/homes.txt"; touch "$FAKE/refuse_home"
run ./03_launcher_wechsel.sh 1.2.3.4; grep -q "automatisch wieder aktiviert" "$W/out.txt" && ok "Abbruch gemeldet" || ko "kein Abbruch"
grep -qx com.google.android.tvlauncher "$FAKE/disabled.txt" && ko "Stock-Launcher blieb aus" || ok "Stock-Launcher sofort wieder an"

echo "T15 Diagnose ohne Parameter ändert nichts"; setup; run ./00_backup.sh 1.2.3.4
before="$(cat "$FAKE/disabled.txt")"; run ./04_diagnose_launcher.sh 1.2.3.4
[ "$(cat "$FAKE/disabled.txt")" = "$before" ] && ok "Zustand unverändert" || ko "Zustand verändert"
ls "$D"/state/diagnose_*/summary.txt >/dev/null 2>&1 && ok "summary.txt erzeugt" || ko "keine Zusammenfassung"
grep -q "pm disable\|pm enable" "$FAKE/calls.log" && ko "ändernder Befehl im Lesemodus" || ok "kein ändernder Befehl"

echo "T16 Reboot-Test erkennt Reaktivierung beim Boot"; setup; run ./00_backup.sh 1.2.3.4
echo com.spocky.projengmenu >> "$FAKE/packages.txt"; echo com.spocky.projengmenu >> "$FAKE/homes.txt"; echo com.google.android.tvlauncher > "$FAKE/reenable_at_boot"
run ./04_diagnose_launcher.sh 1.2.3.4 --reboot-test
grep -A1 "Nach dem Boot wieder eingeschaltet" "$W/out.txt" | grep -q tvlauncher && ok "Reaktivierung erkannt" || { ko "nicht erkannt"; tail -20 "$W/out.txt"; }
grep -q "en com.google.android.tvlauncher" "$D/state/rollback_launcher.sh" && ok "Rollback vorab geschrieben" || ko "kein Rollback"

echo "T11 Nie verbotene Befehle"
[ ! -s "$FAKE/forbidden.log" ] && ok "kein uninstall/clear/hide aufgerufen" || ko "$(cat "$FAKE/forbidden.log")"
grep -rnE 'pm (uninstall|clear|hide)|rm -rf' "$DEV"/*.sh && ko "verbotener Befehl im Code" || ok "kein uninstall/clear/hide/rm -rf im Code"

echo; echo "Ergebnis: $pass OK, $failc FAIL"; [ "$failc" = 0 ]
