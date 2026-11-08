#!/usr/bin/env bash
# Backup aller Paketlisten vom TV. Aufruf: ./00_backup.sh <TV-IP>
set -euo pipefail
IP="${1:?Bitte TV-IP angeben, z. B. ./00_backup.sh 192.168.1.50}"
adb connect "$IP:5555"
adb wait-for-device
D="backup_$(date +%Y%m%d_%H%M%S)"; mkdir -p "$D"
adb shell getprop ro.product.model        > "$D/model.txt"
adb shell getprop ro.build.fingerprint    > "$D/firmware.txt"
adb shell pm list packages     | sed 's/^package://' | sort > "$D/original_packages.txt"
adb shell pm list packages -s  | sed 's/^package://' | sort > "$D/system_packages.txt"
adb shell pm list packages -3  | sed 's/^package://' | sort > "$D/user_packages.txt"
adb shell pm list packages -d  | sed 's/^package://' | sort > "$D/already_disabled.txt"
adb shell cmd package resolve-activity --brief -c android.intent.category.HOME -a android.intent.action.MAIN > "$D/default_launcher.txt" || true
echo "Backup in $D:"; wc -l "$D"/*.txt
echo; echo "waipu.tv-Paket:"; grep -iE 'waipu|exaring' "$D/original_packages.txt" || echo "  (nicht gefunden – bitte prüfen)"
