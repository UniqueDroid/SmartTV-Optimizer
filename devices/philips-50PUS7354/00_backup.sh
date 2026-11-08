#!/usr/bin/env bash
# Schritt 0: Vollständiges Backup des Ist-Zustands. Ändert NICHTS am TV.
# Aufruf: ./00_backup.sh <TV-IP>
source "$(dirname "$0")/lib.sh"
init_device "${1:-}"
B="$STATE/backup_$(date +%Y%m%d_%H%M%S)"; mkdir -p "$B"
sh_ getprop                      > "$B/getprop.txt"
sh_ getprop ro.build.fingerprint > "$B/firmware.txt"
list_pkgs        > "$B/original_packages.txt"
list_pkgs -e     > "$B/enabled.txt"
list_pkgs -d     > "$B/disabled_ab_werk.txt"
list_pkgs -s     > "$B/system.txt"
list_pkgs -3     > "$B/user_apps.txt"
list_pkgs -u     > "$B/inkl_deinstalliert_fuer_user0.txt"
tvinput_providers > "$B/tvinput_providers.txt"
home_handlers     > "$B/home_handlers.txt"
current_home      > "$B/home_aktuell.txt"
sh_ dumpsys tv_input > "$B/dumpsys_tv_input.txt"
for ns in global secure system; do sh_ settings list "$ns" > "$B/settings_$ns.txt"; done
[ -s "$B/original_packages.txt" ] || die "Paketliste leer – Backup ungültig"

# Notfall-Wiederherstellung: alles einschalten, was beim Backup eingeschaltet war.
R="$B/restore_from_backup.sh"; rb_init "$R"
while read -r p; do rb_add "$R" "$p"; done < "$B/enabled.txt"
ln -sfn "$(basename "$B")" "$STATE/LATEST"

echo "Backup: $B"; wc -l "$B"/*.txt | sed 's#'"$B"'/##'
echo; echo "Aktueller HOME: $(cat "$B/home_aktuell.txt")"
echo "TvInput-Anbieter (werden nie deaktiviert):"; sed 's/^/  /' "$B/tvinput_providers.txt"
echo "waipu.tv: $(grep -iE 'waipu|exaring' "$B/original_packages.txt" || echo 'NICHT gefunden – bitte prüfen')"
echo "Factory-deaktiviert (wird von uns nie eingeschaltet): $(wc -l < "$B/disabled_ab_werk.txt") Pakete"
