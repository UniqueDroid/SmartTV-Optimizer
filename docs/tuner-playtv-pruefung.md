# Prüfung: `org.droidtv.playtv` deaktivieren (Batch 5) – Stand 2026-11-08

Frage: Beseitigt das Deaktivieren von `org.droidtv.playtv` die „Kein Signal/Keine Sender“-Meldung beim Einschalten, und bootet der TV danach direkt in den Home-Screen?

## Ergebnis
**Nicht belegt. Batch 5 ist auskommentiert und wird vorerst nicht ausgeführt.**

| Behauptung | Beleg |
|---|---|
| „Kein Signal“-Falle beim Einschalten und auf der TV-Taste entfällt | nur eine unbelegte Aussage, siehe unten |
| HDMI-Umschaltung bleibt (läuft über `org.droidtv.channels`) | dieselbe Aussage; plausibel, weil die Quellenwahl ein eigenes Paket ist |
| **TV bootet danach direkt in den Home-Screen** | **wird in der Quelle gar nicht behauptet** |
| Android-Version | Kopf der Liste: Android 12, Firmware STT2.230526.001 – auf welchem Gerät und welcher Version der Beitragende tatsächlich getestet hat, ist **nicht dokumentiert** |

## Herkunft der Aussage
- cleanyourtv, Commit `deadc0a9` vom 2026-11-03, **ein einzelner Beitragender**. Der Text wurde wortgleich in zwei Gerätelisten eingefügt (`philips-65pus9435`, `philips-tpm191e`).
- Anders als die übrigen Einträge gibt es **kein Testprotokoll**: kein Gerät/Modell, kein Datum, keine Zahl der Neustarts, keine Log-Zeilen.
- Die Maintainer haben die Zeilen danach **auskommentiert** („Left as comments: uncomment them only if you never watch broadcast TV … The tester had them off“).
- Zum Vergleich: Die Batches 1 und 2 sind auf zehn Geräten mit identischer Firmware protokolliert, Batch 5 auf keinem.

## Was über das Bootverhalten tatsächlich dokumentiert ist
- Die Firmware startet bei **jedem** Einschalten erst die FallbackHome und danach `PlayTvActivity` (`wm_set_resumed_activity`, auf mehreren TPM191E-Geräten protokolliert).
- Wer `playtv` startet, ist **unbekannt** (ein Philips-Dienst, „letzte Quelle wiederherstellen“?).
- Ist `playtv` deaktiviert, schlägt dieser Start fehl. Ob der Aufrufer das sauber abfängt, ist offen. Ist er ein dauerhaft laufender Systemdienst und stürzt bei dem Fehler ab, sind **Absturz- oder Neustartschleifen denkbar**. Die Prüfung im Skript (playtv selbst ist nicht PERSISTENT) deckt dieses Risiko **nicht** ab.
- Selbst wenn es klappt: Danach landet man auf dem aktuellen HOME, auf diesem Gerät derzeit wieder `tvlauncher`, weil der sich beim Boot selbst einschaltet. Projectivy wäre es nicht automatisch.
- Belegt, auf vier oder mehr TPM191E-Geräten: Ein Launcher, der nach dem Einschalten selbst nach vorne kommt (cleanyourtv-Launcher `power_on_home_always`), bringt Home etwa 7–13 s nach dem Einschalten zurück, **ohne** dass `playtv` deaktiviert wird.

## Vorgehen, bevor Batch 5 überhaupt in Frage kommt
1. Aufrufer ermitteln, nur lesend: `./04_diagnose_launcher.sh <TV-IP>` direkt nach einem normalen Einschalten. In `state/diagnose_*/vorher_logcat_filter.txt` nach Zeilen wie `START u0 {… cmp=org.droidtv.playtv/… } from uid …` suchen. Die uid zeigt, wer startet (`pm list packages -U | grep <uid>`).
2. Ist der Aufrufer ein PERSISTENT-Systemdienst (`dumpsys package <aufrufer> | grep pkgFlags`), bleibt Batch 5 gesperrt.
3. Erst dann, mit Jans OK: nur `playtv` in eine eigene Batch-Datei, `ALLOW_TUNER=1`, danach `02_reboot_check.sh`. Mehrere Kalt- und Warmstarts testen und das Ergebnis hier eintragen.

## Quelle
- Gathin23/cleanyourtv: `examples/philips-tpm191e/debloat.txt` (Batch 5, auskommentiert), Commit `deadc0a9`; `examples/philips-tpm191e/README.md` (Bootreihenfolge FallbackHome → PlayTvActivity, `power_on_home_always`).
