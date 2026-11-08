# Repo-Recherche: Philips 50PUS7354/12 (TPM191E) – Stand 2026-11-08

## Ergebnis
Es gibt bereits eine community-getestete Debloat-Liste für exakt diese Plattform:
- Repo: https://github.com/Gathin23/cleanyourtv
- Ordner: `examples/philips-tpm191e/` (debloat.txt, README.md, tv.json)
- Plattform: TP Vision TPM191E (PH9M_EA_5599, MediaTek MT5887), Android TV 12, Firmware STT2.230526.001
- Im Ordner ausdrücklich genannt: 50PUS7354 (Frankreich, WLAN) und 65PUS7354 (Portugal, Ethernet) – gleiche Board/Firmware.
- Apply/Undo laut Repo: `tools/disable.sh` / `tools/restore.sh` (NICHT geprüft, ob nur `pm disable-user --user 0` genutzt wird – vor Nutzung lesen).

Ergänzend: https://github.com/humblemuzzu/dumbtv – `catalog/devices/androidtv-philips-tpm191e.yaml` (55OLED705/12, gleiche Firmware).

Weitere Repos (nur generisch / andere Marken): seun-novodev/android-tv-debloat-toolkit, amirulmzlan/android-tv-debloat, caferyukseloglu/android-tv-debloat, UAD-ng (Universal Android Debloater Next Generation). Philips-Paketlisten fehlen dort weitgehend.

## Inhalt der Liste (Paketnamen, Kommentare sinngemäß)
- Batch 1 – Telemetrie/Demo: org.droidtv.candeebug, org.droidtv.gel, org.droidtv.usagelogger, org.droidtv.demome, com.google.android.feedback, com.google.android.partnersetup, com.google.android.onetimeinitializer, com.google.android.syncadapters.calendar
- Batch 2 – Philips-Promo: org.droidtv.nettvrecommender, org.droidtv.recommendation, org.droidtv.nettv.market
- Batch 3 – nach Rücksprache (nutzerabhängig): com.google.android.katniss (Assistant/Sprache), com.amazon.amazonvideo.livingroom, com.google.android.videos, com.google.android.music, com.google.android.youtube.tvmusic, com.google.android.play.games, com.google.android.marvin.talkback, org.droidtv.dlna, com.phorus.playfi.softap
- Batch 4 – NUR mit Ersatz-Launcher: com.google.android.tvrecommendations
- Bewusst behalten: org.droidtv.amazonalexa, com.google.android.apps.mediashell (Chromecast), org.droidtv.oad, com.easy.oad (Firmware-Updates), org.droidtv.eum

## Abgleich mit Projektregeln
- Batch 1 + 2: passt zu Regel 5 (Telemetrie/Promo) → Kandidaten für [Sicher zu deaktivieren], nach Abgleich mit echter `pm list packages`.
- Batch 3: [Hersteller-Apps nach Rücksprache]; katniss kollidiert mit „Sprachassistent behalten“.
- Batch 4 / Launcher: Regel 4 – erst Projectivy/FLauncher installieren, testen, als Standard setzen. Nie com.google.android.tvlauncher / launcherx vorher deaktivieren.
- Nebenwirkung: Netflix-/Rakuten-/App-Gallery-Fernbedienungstasten (Scancodes 632/779/695) funktionieren nach Deaktivierung nicht mehr ohne Remapping.
- Evidenz: Einzelsitzungen; Streaming, Tuner, HDMI, USB nicht validiert.
