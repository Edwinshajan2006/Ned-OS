#!/usr/bin/env bash
set -u
root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
failures=0; warnings=0
pass() { printf 'PASS  %s\n' "$1"; }; warn() { printf 'WARN  %s\n' "$1"; warnings=$((warnings + 1)); }; fail() { printf 'FAIL  %s\n' "$1"; failures=$((failures + 1)); }
[[ -d "$root_dir" ]] && pass "project directory: $root_dir" || fail 'project directory is missing'
for file in scripts/ned scripts/system-status.sh scripts/ned-info.sh scripts/ned-wallpaper.sh scripts/ned-doctor.sh; do [[ -x "$root_dir/$file" ]] && pass "executable: $file" || fail "not executable: $file"; done
[[ -f "$root_dir/config/fastfetch/config.jsonc" ]] && pass 'project Fastfetch configuration' || fail 'project Fastfetch configuration missing'
command -v fastfetch >/dev/null 2>&1 && pass 'Fastfetch available' || warn 'Fastfetch is not installed'
command -v plank >/dev/null 2>&1 && pass 'Plank available' || warn 'Plank is not installed'
pgrep -x plank >/dev/null 2>&1 && pass 'Plank running' || warn 'Plank is not running in this session'
command -v eww >/dev/null 2>&1 && pass 'Eww available' || warn 'Eww is not installed'
[[ -f "$root_dir/assets/wallpapers/ned-os-mountain.png" ]] && pass 'default wallpaper asset' || fail 'default wallpaper asset missing'
autostart="${XDG_CONFIG_HOME:-$HOME/.config}/autostart/ned-os.desktop"
[[ -f "$autostart" ]] && pass 'NED-OS autostart entry' || warn 'NED-OS autostart entry not installed'
if command -v desktop-file-validate >/dev/null 2>&1 && [[ -f "$autostart" ]]; then desktop-file-validate "$autostart" >/dev/null 2>&1 && pass 'autostart entry syntax' || fail 'autostart entry syntax is invalid'; fi
available=$(df -Pk "$HOME" 2>/dev/null | awk 'NR == 2 { print int($4 / 1024) }')
[[ "${available:-0}" -ge 2048 ]] && pass "disk headroom: ${available} MiB" || warn "low disk headroom: ${available:-unknown} MiB"
mem_available=$(awk '/MemAvailable:/ { print int($2 / 1024) }' /proc/meminfo 2>/dev/null)
[[ "${mem_available:-0}" -ge 512 ]] && pass "available memory: ${mem_available} MiB" || warn "low available memory: ${mem_available:-unknown} MiB"
printf '\nResult: %s failure(s), %s warning(s).\n' "$failures" "$warnings"; (( failures == 0 ))
