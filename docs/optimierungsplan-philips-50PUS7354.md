# Optimierungsplan: Philips 50PUS7354/12 (TPM191E) – Stand 2026-11-08 (geprüft)

## Gerätedaten
- Hersteller & Modell: Philips 50PUS7354/12, Plattform TPM191E (PH9M_EA_5599, MediaTek MT5887)
- Betriebssystem: Android TV 12 (erwartete Firmware STT2.230526.001 – wird per Backup bestätigt)
- Live-TV: ausschließlich **waipu.tv** (vermutlich `de.exaring.waipu`), keine Antenne/Kabel/Sat
- Genutzte Streaming-Dienste: **YouTube, Netflix, Amazon Prime Video, Disney+, Twitch** → hart geschützt
- Beibehaltene Features: Fernbedienung/Bluetooth, WLAN, HDMI-CEC, Quellen-Menü, Firmware-Updates, Chromecast (bis zur Entscheidung). Offen: Google Assistant, Alexa

## Grundsätze
- Nur `pm disable-user --user 0`, nie deinstallieren. Rückweg immer `pm enable --user 0`.
- Rollback-Zeile wird vor jeder Änderung geschrieben; Backup erzeugt zusätzlich ein Komplett-Restore.
- Nur Pakete, die auf derselben Firmware (TPM191E, STT2.230526.001) von der Community über Neustarts getestet wurden – darunter ein 50PUS7354.
- Nach jedem Batch: `02_reboot_check.sh` (Neustart, Boot-Prüfung, automatischer Rollback bei Bootproblem).

## Batches
| Batch | Inhalt | Kategorie | Evidenz |
|---|---|---|---|
| 1 Telemetrie | candeebug, gel, usagelogger, demome, google.feedback, partnersetup, onetimeinitializer, syncadapters.calendar | Sicher | 10 TPM191E-Geräte, u. a. 50PUS7354 |
| 2 Promo | nettvrecommender, recommendation, nettv.market (App-Gallery-Taste geht danach nicht mehr) | Sicher | wie oben |
| 2b Extras | nettvapps, sticker, dropboxprovider, Web-App-Kacheln nettvappNNNN (nach Backup) | Nach Rücksprache | 50PUS7354, 2 Neustarts |
| 3 Apps | Google TV Filme, Play Musik, YouTube Music, Play Games, Play-Fi softap; optional DLNA, Alexa, TalkBack, Assistant | Nach Rücksprache | mehrere Geräte |
| 4 tvrecommendations | nur wenn Ersatz-Launcher HOME **und** Stock-Launcher aus – derzeit nicht geplant | Kritisch | – |
| 5 Tuner | org.droidtv.playtv, danach ggf. Installer/Videotext; nur `ALLOW_TUNER=1` | Kritisch | 1 Tester |

## Tuner (Korrektur 2026-11-08)
Frühere Annahme „playtv steuert auch HDMI“ war zu vorsichtig: Laut cleanyourtv (TPM191E) läuft die HDMI-Umschaltung über `org.droidtv.channels` (bleibt hart geschützt). Das Deaktivieren von `org.droidtv.playtv` soll die „Kein Signal“-Falle beim Einschalten beseitigen – getestet von nur einem Tester. Daher:
1. Erst Batches 1–3, jeweils mit Neustart-Check.
2. Dann Batch 5 mit nur `playtv`, Neustart-Check, mehrere Tage nutzen.
3. Installer/Videotext nur bei Bedarf.
Ein Bootschleifen-Risiko ist gering (App ohne PERSISTENT-Flag, kein TV-Eingangs-Anbieter – das Skript prüft beides vor dem Deaktivieren), aber nicht null. Alternative ohne Eingriff: Projectivy Launcher mit waipu.tv-Autostart.

## Nie deaktivieren (hart, Skript bricht ab)
`android`, `com.android.*`, GMS/GSF/WebView/Setup/Launcher/Tastatur, `com.mediatek.*`, `org.droidtv.{tvserver,channels,eum,fastip,philipstvdrawer,nettvbrowser,menudataapp,nettvregistration,tvsystemui,icp,oad,settings,tv.*,nettv_launcherapp}`, `com.easy.oad`, HbbTV-Engines (vewd/seraphic), `com.phorus.playfi.tv`, Chromecast, waipu.tv, YouTube, Netflix, Prime Video, Disney+, Twitch, alles mit bluetooth/wifi/remote/hdmi/launcher/settings/keyboard im Namen.

## Bekannte Eigenheiten der Plattform
- TV bootet direkt in Live-TV (playtv) statt in den Home-Screen.
- usagelogger/demome/playfi.tv können sich beim Boot wieder einschalten – harmlos, wird im Check gemeldet.
- Kein Private DNS (DoT) setzen: Nach Stromausfall startet die Uhr im Dez. 2025, TLS scheitert vor der NTP-Synchronisation → kein Netz.
- Einzige HOME-Handler: tvlauncher und FallbackHome der Settings (schwarzer Bildschirm).

## Offen
- Wortlaut der wiederkehrenden Meldung (Vermutung: „Kein Signal/keine Sender“ durch Boot in playtv)
- Google Assistant, Alexa, DLNA behalten?
- Projectivy Launcher gewünscht?

## Quellen
- Gathin23/cleanyourtv – `examples/philips-tpm191e/debloat.txt` (10 Geräte, u. a. 50PUS7354 Frankreich und 65PUS7354)
- humblemuzzu/dumbtv – `catalog/devices/androidtv-philips-tpm191e.yaml`
