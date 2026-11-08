# Home-Taste öffnet weiter den Stock-Launcher – Philips TPM191E (Android TV 12)

Stand 2026-11-08. Gilt für Philips 50PUS7354/12 und andere TPM191E-Geräte (Firmware STT2.230526.001) mit Projectivy Launcher (`com.spocky.projengmenu`).

## Ursache
- Der Stock-Launcher `com.google.android.tvlauncher` meldet seinen HOME-Filter mit **Priorität 2**, Drittanbieter-Launcher mit 0. Android wählt deshalb immer den Stock-Launcher. Projectivy als „Standard“ einzustellen ändert daran nichts.
- `cmd package set-home-activity …` meldet zwar „Success“, wird aber ignoriert, solange `tvlauncher` aktiv ist (beobachtet auf TPM191E, dumbtv-Katalog).
- Auf TPM191E gibt es nur zwei HOME-Handler: `tvlauncher` und die FallbackHome der Settings (= schwarzer Bildschirm).
- Unabhängig davon öffnet die Firmware bei jedem Start zuerst Live-TV (`org.droidtv.playtv`).

## Lösungen

### A) Projectivy-Override per Bedienungshilfe (keine Systemänderung)
1. Projectivy → Einstellungen → Allgemein → **„Aktuellen Launcher überschreiben“** einschalten.
2. Android-Einstellungen → Bedienungshilfen → **Projectivy Launcher** einschalten.
3. Ggf. Einstellungen → Apps → Spezieller App-Zugriff → Benachrichtigungszugriff → Projectivy erlauben.

Nachteile, gerade auf dieser Plattform:
- Auf einem 55PUS9435 (gleiche Plattform/Firmware) hing mit aktivem Projectivy-Bedienungshilfedienst die **Zurück-Taste zeitweise in Philips-Menüs** (Einstellungen, Quellen), jeder Tastendruck kam **100–300 ms verzögert**, und gehaltenes Lautstärke-Hoch/Runter wiederholte nicht mehr (cleanyourtv, TROUBLESHOOTING).
- Der Override hält laut Nutzerberichten nicht immer über einen Neustart; kurz blitzt der Stock-Launcher auf.

## ⚠ Befund auf Jans 50PUS7354 (2026-11-08)
Lösung B wirkte **sofort** (HOME = Projectivy), aber **nach dem Neustart war `tvlauncher` wieder aktiv** und HOME zeigte wieder auf ihn. Die Erfahrung „hält über mehrere Neustarts“ der anderen Geräte trifft hier (noch) nicht zu. Ursache offen – mögliche Erklärungen, in dieser Reihenfolge prüfen:

1. **Eigenes Skript:** `02_reboot_check.sh` rollte bis Commit `cc398dd` den letzten Schritt automatisch zurück, wenn der Boot länger als 300 s dauerte – beim Launcher-Wechsel hieße das `tvlauncher` wieder an. Seitdem: Timeout 600 s, interaktive Rückfrage, jeder Auto-Rollback steht in `state/rollback_events.log`.
2. **Ein Dienst schaltet ihn beim Boot aktiv ein** (User-0-Zustand `enabled=1`, Verursacher im Boot-Log; Kandidaten: `setupwraith`/`tungsten`, Philips-Dienste).
3. **Firmware verwirft Benutzer-Deaktivierungen** (dann sind *alle* `disable-user`-Pakete nach dem Boot wieder an → Konzept „nur deaktivieren“ hält auf diesem Gerät generell nicht).
4. **Andere Firmware** als `STT2.230526.001` → Community-Erfahrungen nicht übertragbar.

Diagnose (`devices/philips-50PUS7354/04_diagnose_launcher.sh`):
```bash
./04_diagnose_launcher.sh <TV-IP>                 # nur lesen
./04_diagnose_launcher.sh <TV-IP> --reboot-test   # deaktivieren → Neustart → Boot-Log sammeln
cat state/diagnose_*/summary.txt
```
`summary.txt` enthält Firmware, HOME, User-0-Zustand (`enabled=` 0 Standard · 1 aktiv eingeschaltet · 3 disabled-user), welche Pakete nach dem Boot wieder an sind, Auto-Rollbacks und Log-Treffer. Volle Logs liegen daneben (`*_logcat_main.txt`, `*_logcat_events.txt`).

Bis zur Klärung: **Lösung A** als Übergang testen – vorher `./state/rollback_launcher.sh <TV-IP>`, damit nicht zwei Mechanismen gleichzeitig wirken.

### B) Stock-Launcher deaktivieren (reversibel – auf Jans Gerät bisher nicht neustartfest, siehe Befund)
`pm disable-user --user 0 com.google.android.tvlauncher` – nicht deinstallieren. Auf mindestens neun anderen TPM191E-Geräten (darunter ein 50PUS7354) übernahm der neue Launcher die Home-Taste **sofort** nach dem Deaktivieren und behielt sie über mehrere Neustarts (cleanyourtv `examples/philips-tpm191e`). Dann ist auch kein Bedienungshilfedienst nötig – Lösung A wieder ausschalten.

Erlaubt nach Projektregel 4 erst, wenn der Ersatz installiert, geöffnet und getestet ist. Das Skript `devices/philips-50PUS7354/03_launcher_wechsel.sh`:
- prüft Backup, dass Projectivy installiert, aktiv und **als HOME-Handler gemeldet** ist (sonst Abbruch – kein schwarzer Bildschirm),
- schreibt die Rollback-Zeile **vor** der Änderung (`state/rollback_launcher.sh`),
- deaktiviert `tvlauncher` und prüft sofort, wohin HOME jetzt zeigt; zeigt es nicht auf Projectivy, wird `tvlauncher` **automatisch wieder aktiviert**.

```bash
cd devices/philips-50PUS7354
./03_launcher_wechsel.sh 192.168.1.50                 # Projectivy (com.spocky.projengmenu)
./02_reboot_check.sh 192.168.1.50                     # Neustart + Prüfung, Auto-Rollback bei Bootproblem
./state/rollback_launcher.sh 192.168.1.50             # Rückweg
```
Anderer Launcher: Paketname als zweiten Parameter, z. B. `me.efesser.flauncher`.

Bekannte Nebenwirkungen von B:
- **Gehaltene Home-Taste** tut evtl. nichts: Android schickt den Langdruck an die System-HOME (FallbackHome). Kurz drücken funktioniert.
- Sprachsuche/Assistant-Ergebnisse können vom Stock-Launcher abhängen; bei Problemen Assistant aus dem Projectivy-Menü/YouTube-Mikro nutzen oder zurückrollen.
- Benachrichtigungs-Seitenleiste bleibt, solange `com.google.android.tvrecommendations` aktiv ist. Batch 4 (tvrecommendations) ist erst jetzt erlaubt – vorher würde der Stock-Launcher abstürzen.

### C) Tastenbelegung (Button Mapper / TV Quick Actions)
Home-Taste auf „Projectivy öffnen“ legen. Nutzt ebenfalls einen Bedienungshilfedienst → gleiche Nachteile wie A.

## Prüfen (ADB, ändert nichts)
```bash
adb shell cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME   # HOME-Handler
adb shell cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME   # aktueller HOME
adb shell settings get secure enabled_accessibility_services                                                   # aktive Bedienungshilfen
```

## Quellen
- Gathin23/cleanyourtv – `examples/philips-tpm191e/README.md` (Home bleibt beim Stock-Launcher wegen Priorität 2, wechselt sofort nach dem Deaktivieren; 50PUS7354-Notizen) und `docs/TROUBLESHOOTING.md` (Projectivy-Bedienungshilfe auf 55PUS9435)
- humblemuzzu/dumbtv – `catalog/devices/androidtv-philips-tpm191e.yaml` (`set-home-activity` wird ignoriert, solange tvlauncher aktiv ist)
- r/Projectivy_Launcher – Override-Einstellung + Bedienungshilfe, Hinweise zur Beständigkeit nach Neustart
