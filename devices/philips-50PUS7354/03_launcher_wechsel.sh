#!/usr/bin/env bash
# Schritt 3: Home-Taste dauerhaft auf den neuen Launcher legen, indem der Stock-Launcher
# DEAKTIVIERT (nicht deinstalliert) wird. Hintergrund: docs/home-taste-launcher.md
# Aufruf: ./03_launcher_wechsel.sh <TV-IP> [launcher-paket]   (Standard: Projectivy com.spocky.projengmenu)
# Rückweg: ./state/rollback_launcher.sh <TV-IP>
source "$(dirname "$0")/lib.sh"
NEW="${2:-com.spocky.projengmenu}"
STOCK="com.google.android.tvlauncher"
init_device "${1:-}"
[ -e "$STATE/LATEST/original_packages.txt" ] || die "Kein Backup – zuerst ./00_backup.sh"
[[ "$NEW" =~ ^[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+$ ]] || die "Ungültiger Paketname $NEW"
EN="$(list_pkgs -e)"
grep -qx "$NEW" <<<"$EN"   || die "$NEW ist nicht installiert/aktiv."
grep -qx "$STOCK" <<<"$EN" || die "$STOCK ist bereits deaktiviert – nichts zu tun."
home_handlers | grep -qx "$NEW" || die "$NEW meldet keine HOME-Activity – würde zu schwarzem Bildschirm führen."
if [ "${YES:-0}" != 1 ]; then
  echo "Voraussetzung: $NEW wurde geöffnet und mehrere Tage getestet (Regel 4)."
  read -r -p "Stock-Launcher $STOCK jetzt deaktivieren? Tippe 'ja': " a </dev/tty; [ "$a" = ja ] || die "Abgebrochen."
fi
RB="$STATE/rollback_launcher.sh"; rb_init "$RB"; rb_add "$RB" "$STOCK"; rb_init "$STATE/rollback_all.sh"; rb_add "$STATE/rollback_all.sh" "$STOCK"
echo "launcher" > "$STATE/LAST_BATCH"
sh_ pm disable-user --user 0 "$STOCK" >/dev/null || true
list_pkgs -d | grep -qx "$STOCK" || die "Deaktivieren fehlgeschlagen – nichts geändert."
H="$(current_home)"; echo "HOME jetzt: ${H:-<leer>}"
if [[ "$H" != "$NEW/"* ]]; then
  # Sofortiger Selbstschutz: HOME zeigt nicht auf den neuen Launcher -> zurück
  sh_ pm enable --user 0 "$STOCK" >/dev/null
  die "HOME zeigt nicht auf $NEW (sondern '${H:-leer}'). Stock-Launcher wurde automatisch wieder aktiviert."
fi
sh_ input keyevent KEYCODE_HOME >/dev/null || true
echo "OK. Jetzt Home-Taste auf der Fernbedienung testen, dann: ./02_reboot_check.sh $SERIAL"
