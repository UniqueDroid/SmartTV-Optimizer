# Optimierungsplan: Philips 50PUS7354/12 (TPM191E) – Stand 2026-11-08

## Gerätedaten
- Hersteller & Modell: Philips 50PUS7354/12, Plattform TPM191E (MediaTek MT5887)
- Betriebssystem: Android TV 12 (Firmware-Stand per `00_backup.sh` auslesen)
- Live-TV: ausschließlich über **waipu.tv** (Paket vermutlich `de.exaring.waipu` – wird im Backup geprüft), kein Antennen-/Kabelempfang
- Genutzte Streaming-Dienste: **YouTube, Netflix, Amazon Prime Video, Disney+, Twitch** → alle geschützt
- Beibehaltene Features: Fernbedienung/Bluetooth, WLAN, HDMI-CEC, Firmware-Updates, Netflix-/Prime-Taste. Offen: Sprachassistent, Chromecast

## Entscheidung Tuner (2026-11-08)
Tuner nur deaktivieren, wenn das ohne Risiko (kein Bootloop) geht → **Tuner-Kern bleibt aktiv.**
Grund: Auf TPM191E ist `org.droidtv.playtv` nicht nur der Tuner, sondern die zentrale TV-App (Quellenwahl, HDMI, Bildwiedergabe); der TV bootet laut Community-Test direkt in playtv statt in den Home-Screen. `org.droidtv.tvserver` hängt an Bild/Ton-Hardware. Deaktivieren → Risiko schwarzer Bildschirm/HDMI weg/Bootschleife.
Stattdessen: Startverhalten ändern (Projectivy mit waipu.tv-Autostart), danach ggf. einzelne Neben-Pakete (Senderliste/EPG/HbbTV) nach Prüfung der echten Paketliste einzeln testen.

## Problem: wiederkehrende Meldung
Wortlaut noch offen. Vermutung: TV bootet in Live-TV (playtv) ohne installierte Sender → „Keine Sender / Sendersuche starten?“.
- Lösung: Startverhalten auf Home/Launcher, bzw. Projectivy startet waipu.tv beim Einschalten.
- Alternativ Nutzungsbedingungen/Datenschutz-Abfrage → einmalig zustimmen/ablehnen.

## Ablauf
1. **Vorbereitung**: Entwickleroptionen + Netzwerk-Debugging an, IP notieren.
2. **Backup**: `./00_backup.sh <TV-IP>` → original_packages.txt usw.
3. **Kategorisierung** mit echter Paketliste → Freigabe.
4. **Batch 1 – Telemetrie/Demo** (sicher): candeebug, gel, usagelogger, demome, google.feedback, partnersetup, onetimeinitializer, syncadapters.calendar → Neustart, Test.
5. **Batch 2 – Philips-Werbung** (sicher): nettvrecommender, recommendation, nettv.market; zusätzlich Kandidaten `org.droidtv.nettvappNNNN` (Web-App-Verknüpfungen wie Couchplay, Arte, Deezer …) → Neustart, Test.
6. **Batch 3 – nach Rücksprache**: Google TV Filme, Google Music, YouTube Music, Play Games, DLNA, Play-Fi, Alexa; optional Assistant (katniss).
7. **Launcher**: Projectivy Launcher installieren, als Standard setzen, waipu.tv als Autostart, einige Tage testen. Erst dann Batch 4 (tvrecommendations). Stock-Launcher bleibt aktiviert.

## Nie deaktivieren
gms, gsf, com.android.providers.*, vending, launcherx/tvlauncher, Bluetooth/WLAN/Fernbedienung, HALs, HDMI/CEC, Tuner/TV-Kern (org.droidtv.playtv/tvserver/channels), Settings, Tastatur (leanbackime), WebView, systemui, OAD/Firmware-Update, waipu.tv, YouTube, Netflix, Prime Video, Disney+, Twitch. Die Skripte prüfen das per `whitelist.regex`.

## Werkzeuge (`devices/philips-50PUS7354/`)
- `00_backup.sh` – Paketlisten sichern
- `01_disable_batch.sh <batch>` – nur `pm disable-user --user 0`, protokolliert jedes Paket in `rollback.sh` (`pm enable`)
- `batches/` – Batch 1–4
- `whitelist.regex` – geschützte Pakete

## Offen
- Wortlaut der wiederkehrenden Meldung
- Sprachassistent und Chromecast behalten?
- Projectivy Launcher gewünscht?

## Quellen
- humblemuzzu/dumbtv – `catalog/devices/androidtv-philips-tpm191e.yaml` (Boot in playtv, nettvapp-Verknüpfungen, Telemetrie-Pakete)
- Gathin23/cleanyourtv – `examples/philips-tpm191e/`
