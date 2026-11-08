# SmartTV-Optimizer

Vorsichtiges, vollständig reversibles Debloating von Android-TV-/Google-TV-Geräten per ADB – ohne Root.

## Grundregeln (von den Skripten erzwungen)
1. **Nichts wird deinstalliert.** Einziger ändernder Befehl: `pm disable-user --user 0 <paket>`. Rückweg: `pm enable --user 0 <paket>`. Kein `uninstall`, `clear`, `hide` – ein Test prüft das.
2. **Backup first.** Ohne Backup verweigert `01_disable_batch.sh` den Start. Das Backup erzeugt zusätzlich `restore_from_backup.sh`, das alles einschaltet, was beim Backup an war (ab Werk Deaktiviertes bleibt aus).
3. **Rückweg vor Änderung.** Jede Rollback-Zeile wird geschrieben, *bevor* das Paket deaktiviert wird (pro Batch + gesamt).
4. **Harte Whitelist** (`whitelist_hard.regex`): Android-Kern (`android`, `com.android.*`), GMS/Play Store, MediaTek-Middleware, Launcher, Setup, Tastatur, Bluetooth/WLAN/Fernbedienung, HDMI/CEC, Quellen-Menü (`org.droidtv.channels`, `eum`, `fastip`, `philipstvdrawer`), Firmware-Updates, Chromecast und alle genutzten Apps. Steht so ein Paket in einer Batch-Liste, wird der **ganze Batch abgebrochen**.
5. **Automatische Bootschutz-Prüfungen pro Paket:** übersprungen werden Pakete, die einen TV-Eingang bereitstellen (TvInputService), HOME-Handler sind oder als `PERSISTENT` laufen (Bootschleifen-Risiko).
6. **Launcher-Wechsel** nur per `03_launcher_wechsel.sh`: Ersatz muss als HOME-Handler gemeldet sein, sonst Abbruch; zeigt HOME danach nicht auf ihn, wird der Stock-Launcher sofort wieder aktiviert.
7. **Tuner** nur über `batch5_tuner.txt` *und* `ALLOW_TUNER=1`. **Batch 4** nur, wenn ein Ersatz-Launcher HOME ist und der Stock-Launcher bereits aus ist.
8. **Kleine Batches + Neustart-Check.** `02_reboot_check.sh` startet neu, wartet auf den Boot und prüft HOME, HDMI-Eingänge, waipu.tv und Whitelist. Bootet der TV nicht fertig, wird der letzte Batch **automatisch zurückgerollt**.

## Geräte
| Gerät | Plattform | Ordner |
|---|---|---|
| Philips 50PUS7354/12 | TPM191E, Android TV 12 | [`devices/philips-50PUS7354`](devices/philips-50PUS7354) |

## Ablauf (Philips)
```bash
cd devices/philips-50PUS7354
./00_backup.sh 192.168.1.50                                   # ändert nichts
./01_disable_batch.sh 192.168.1.50 batches/batch1_telemetrie.txt
./02_reboot_check.sh 192.168.1.50                             # Neustart + Prüfung
./03_launcher_wechsel.sh 192.168.1.50                         # Home-Taste → Projectivy (Stock-Launcher deaktivieren)
./04_diagnose_launcher.sh 192.168.1.50 [--reboot-test]        # Wer schaltet tvlauncher beim Boot ein?
# bei Problemen:
./state/rollback_batch1_telemetrie.sh 192.168.1.50            # nur dieser Batch
./state/rollback_all.sh 192.168.1.50                          # alles von uns Deaktivierte
./state/LATEST/restore_from_backup.sh 192.168.1.50            # Zustand laut Backup
```
Bash unter Linux, macOS oder WSL; `adb` im PATH. Die Ordner unter `state/` (Backups, Rollbacks) mit einchecken.

## Notfall
- **TV startet, aber etwas fehlt:** passendes Rollback-Skript ausführen.
- **TV bootet nicht fertig, ADB erreichbar:** `02_reboot_check.sh` rollt automatisch zurück; sonst Rollback-Skript manuell.
- **TV bootet nicht und ADB ist nicht erreichbar:** Netzwerk-ADB braucht ein laufendes System. Letzter Rückweg ist ein Werksreset (über das Menü oder den Recovery-Modus laut Philips-Support). Der Reset hebt alle `disable-user`-Änderungen auf, weil nichts deinstalliert wurde – Einstellungen und Logins gehen dabei aber verloren. Genau deshalb: kleine Batches, nur getestete Pakete, Neustart nach jedem Batch.

## Tests
`tests/run_tests.sh` prüft die Skripte offline gegen eine simulierte `adb` (Backup-Pflicht, Whitelist, Tuner-/Launcher-Sperren, Rollback, Stopp bei Fehlern, automatischer Rollback bei Bootschleife, keine verbotenen Befehle).

## Dokumentation
- [Optimierungsplan Philips 50PUS7354](docs/optimierungsplan-philips-50PUS7354.md)
- [CLAUDE.md – Regeln & nächste Aufgabe für Claude](CLAUDE.md)
- [Home-Taste öffnet Stock-Launcher](docs/home-taste-launcher.md)
- [Repo-Recherche Philips TPM191E](docs/repo-recherche-philips-50PUS7354.md)
