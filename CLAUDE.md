# CLAUDE.md – SmartTV-Optimizer

Repo für vorsichtiges, vollständig reversibles Debloating von Android-TV-Geräten per ADB. Aktuelles Gerät: **Philips 50PUS7354/12 (TPM191E, Android TV 12)** in `devices/philips-50PUS7354/`. Sprache: Deutsch.

## Harte Regeln (nie brechen)
1. **Nie deinstallieren.** Kein `pm uninstall`, `pm clear`, `pm hide`, kein Löschen auf dem TV. Einziger ändernder Befehl: `pm disable-user --user 0 <paket>`, Rückweg `pm enable --user 0 <paket>`.
2. **Nichts ohne Backup** (`00_backup.sh`) und nichts ohne vorher geschriebene Rollback-Zeile. Änderungen nur über die Skripte, nicht per Hand-`adb`.
3. **Whitelist** (`whitelist_hard.regex`) nie aufweichen, um einen Batch durchzubekommen. Tuner nur via `batch5_tuner.txt` + `ALLOW_TUNER=1`.
4. **Stock-Launcher** (`com.google.android.tvlauncher`) nur über `03_launcher_wechsel.sh` bzw. `04_diagnose_launcher.sh --reboot-test` anfassen.
5. **Kein Bootloop-Risiko eingehen:** kleine Batches, nach jedem `02_reboot_check.sh`. Unklare Pakete erst mit `dumpsys package` prüfen und Jan fragen.
6. **Vor jeder ändernden Aktion Jan fragen** (Batches, Launcher, Tuner). Lesen/Diagnose ist ohne Rückfrage ok.
7. Nach Änderungen an Skripten: `tests/run_tests.sh` muss grün sein.
8. Erkenntnisse vom echten Gerät in `docs/` festhalten (Befund, Datum, Ursache, Quelle) und `state/` (Backups, Rollbacks, Diagnosen) mit einchecken.

## Aktueller Stand (2026-11-08)
- Projectivy Launcher (`com.spocky.projengmenu`) installiert.
- `03_launcher_wechsel.sh`: HOME = Projectivy sofort ok, **nach Neustart war tvlauncher wieder aktiv**. Ursache offen → `docs/home-taste-launcher.md`, Abschnitt „Befund“.
- Batch 5 (Tuner/playtv) ist **gesperrt/auskommentiert**: Aussage unbelegt, Bootaufrufer unbekannt → `docs/tuner-playtv-pruefung.md`. Nicht aktivieren, bevor der Aufrufer ermittelt ist und Jan zustimmt.
- Batches 1–4 vorbereitet; ob/welche schon gelaufen sind, steht in `devices/philips-50PUS7354/state/` (rollback_*.sh, LAST_BATCH).

## Nächste Aufgabe
1. `state/rollback_events.log` prüfen: Hat ein Auto-Rollback von `02_reboot_check.sh` tvlauncher wieder eingeschaltet? Falls ja → Ursache gefunden, Lösung B mit neuem Timeout (600 s) wiederholen.
2. Sonst `./04_diagnose_launcher.sh <TV-IP>` (nur lesen), dann mit Jans OK `./04_diagnose_launcher.sh <TV-IP> --reboot-test`.
3. `state/diagnose_*/summary.txt` auswerten:
   - nur tvlauncher wieder an, `enabled=1` → Verursacher im `*_logcat_filter.txt` / vollen Logs suchen; Gegenmaßnahme nur reversibel und mit Jans OK.
   - **alle** Deaktivierungen weg → Firmware verwirft disable-user; Jan informieren, Konzept anpassen.
   - Firmware ≠ `STT2.230526.001` → Community-Listen nur eingeschränkt gültig, dokumentieren.
4. Übergangslösung, falls Jan sie will: Projectivy-Override per Bedienungshilfe (Lösung A). Vorher `./state/rollback_launcher.sh <TV-IP>`. Bekannte Nachteile: Tastenverzögerung, Zurück-Taste hängt teils in Philips-Menüs.
5. Ergebnis in `docs/home-taste-launcher.md` eintragen, committen, pushen.

## Offene Fragen an Jan
- Wortlaut der wiederkehrenden Einschalt-Meldung (Vermutung: „Kein Signal/keine Sender“ wegen Boot in Live-TV).
- Google Assistant, Alexa, DLNA behalten?
