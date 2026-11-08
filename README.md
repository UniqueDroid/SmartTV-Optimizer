# SmartTV-Optimizer

Vorsichtiges, vollständig reversibles Debloating von Android-TV-/Google-TV-Geräten per ADB – ohne Root.

## Grundregeln
1. **Nie `pm uninstall`** – ausschließlich `pm disable-user --user 0 <paket>`.
2. **Backup first** – vor jeder Änderung Paketlisten sichern; jedes deaktivierte Paket wird als `pm enable`-Zeile in `rollback.sh` protokolliert.
3. **Whitelist** – Core-Dienste (GMS, Provider, Play Store), Bluetooth/WLAN/Fernbedienung, HALs, HDMI/CEC, Tuner, Settings, Tastatur und genutzte Apps werden von den Skripten automatisch übersprungen.
4. **Launcher** – Stock-Launcher erst deaktivieren, wenn ein Ersatz (z. B. Projectivy) installiert, getestet und Standard ist.
5. **Kleine Batches** – nach jedem Batch Neustart und Funktionstest.

## Geräte
| Gerät | Plattform | Ordner |
|---|---|---|
| Philips 50PUS7354/12 | TPM191E, Android TV 12 | [`devices/philips-50PUS7354`](devices/philips-50PUS7354) |

## Benutzung (Beispiel Philips)
```bash
cd devices/philips-50PUS7354
./00_backup.sh 192.168.1.50                       # Paketlisten sichern
./01_disable_batch.sh batches/batch1_telemetrie.txt
adb reboot                                        # testen!
./rollback.sh                                     # bei Problemen alles zurück
```
Bash unter Linux, macOS oder WSL; `adb` muss im PATH liegen.

## Dokumentation
- [Optimierungsplan Philips 50PUS7354](docs/optimierungsplan-philips-50PUS7354.md)
- [Repo-Recherche Philips TPM191E](docs/repo-recherche-philips-50PUS7354.md)
