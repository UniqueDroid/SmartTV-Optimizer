#!/usr/bin/env bash
# Gemeinsame Funktionen – wird von den anderen Skripten per "source" geladen.
# Grundsatz: Es wird NIE deinstalliert, gelöscht oder geleert. Einziger ändernder Befehl:
#   pm disable-user --user 0 <paket>      Rückweg: pm enable --user 0 <paket>
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE="$HERE/state"
mkdir -p "$STATE"
# HOME-Handler, die als "Stock" gelten (FallbackHome der Settings = schwarzer Bildschirm)
STOCK_HOME_RE='^(com\.google\.android\.tvlauncher|com\.google\.android\.apps\.tv\.launcherx|com\.android\.tv\.settings)(/|$)'
STOCK_LAUNCHERS='com.google.android.tvlauncher com.google.android.apps.tv.launcherx'

die(){ echo "ABBRUCH: $*" >&2; exit 1; }
warn(){ echo "WARNUNG: $*" >&2; }

# Alle adb-Aufrufe gehen mit festem Gerät (-s) und ohne stdin (sonst frisst adb die Paketliste).
sh_(){ adb -s "$SERIAL" shell "$@" </dev/null 2>/dev/null | tr -d '\r'; }

set_serial(){
  local t="${1:-${TV_IP:-}}"
  [ -n "$t" ] || die "TV-IP fehlt: Skript <TV-IP> ...  oder  TV_IP=192.168.x.y"
  [[ "$t" == *:* ]] || t="$t:5555"
  SERIAL="$t"; export ANDROID_SERIAL="$SERIAL"
}

init_device(){
  set_serial "${1:-}"
  adb connect "$SERIAL" >/dev/null 2>&1 || true
  timeout 60 adb -s "$SERIAL" wait-for-device </dev/null || die "TV $SERIAL nicht erreichbar"
  [ "$(sh_ getprop sys.boot_completed)" = "1" ] || die "TV $SERIAL hat noch nicht fertig gebootet"
}

list_pkgs(){ sh_ pm list packages "$@" | sed -n 's/^package://p' | sort -u; }
is_hard_protected(){ grep -qiEf "$HERE/whitelist_hard.regex" <<<"$1"; }
is_tuner(){ grep -qiEf "$HERE/protected_tuner.regex" <<<"$1"; }
# Pakete, die einen TvInputService bereitstellen (HDMI/Tuner-Eingänge) – werden nie angefasst
tvinput_providers(){ sh_ pm query-services --components -a android.media.tv.TvInputService | grep -oE '[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+/' | tr -d / | sort -u; }
# Pakete mit HOME-Activity (Launcher/FallbackHome)
home_handlers(){ sh_ cmd package query-activities --brief -a android.intent.action.MAIN -c android.intent.category.HOME | grep -oE '[A-Za-z0-9_]+(\.[A-Za-z0-9_]+)+/' | tr -d / | sort -u; }
current_home(){ sh_ cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME | tail -n1; }
# PERSISTENT-Apps laufen dauerhaft im System – Abschalten kann Bootschleifen auslösen
is_persistent(){ sh_ dumpsys package "$1" | grep -E 'pkgFlags=\[|^ *flags=\[' | grep -q PERSISTENT; }
hdmi_count(){ sh_ dumpsys tv_input | grep -ciE 'hdmi' || true; }

# Rollback-Datei anlegen (Kopf) – $1 = Pfad
rb_init(){
  [ -f "$1" ] && return 0
  cat > "$1" <<'RB'
#!/usr/bin/env bash
# Automatisch erzeugt. Macht Deaktivierungen rückgängig (pm enable). Aufruf: ./<datei> <TV-IP>
set -u
T="${1:-${TV_IP:-}}"; [ -n "$T" ] || { echo "TV-IP angeben"; exit 1; }
[[ "$T" == *:* ]] || T="$T:5555"
adb connect "$T" >/dev/null 2>&1; adb -s "$T" wait-for-device </dev/null
en(){ printf '%-50s ' "$1"; adb -s "$T" shell pm enable --user 0 "$1" </dev/null | tr -d '\r'; }
RB
  chmod +x "$1"
}
rb_add(){ grep -qx "en $2" "$1" || echo "en $2" >> "$1"; }
