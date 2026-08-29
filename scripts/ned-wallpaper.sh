#!/usr/bin/env bash
set -u
root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
wallpaper="${NED_WALLPAPER:-$root_dir/assets/wallpapers/ned-os-mountain.png}"
usage() { printf 'Usage: ned wallpaper [set|path]\n'; }
case "${1:-set}" in path) printf '%s\n' "$wallpaper"; exit 0 ;; set) ;; *) usage >&2; exit 2 ;; esac
[[ -f "$wallpaper" ]] || { printf 'Wallpaper not found: %s\n' "$wallpaper" >&2; exit 1; }
command -v xfconf-query >/dev/null 2>&1 || { printf 'XFCE settings tool is unavailable.\n' >&2; exit 1; }
found=0
while IFS= read -r property; do
    case "$property" in */image-path|*/last-image)
        xfconf-query -c xfce4-desktop -p "$property" -s "$wallpaper" >/dev/null 2>&1 || true; found=1 ;;
    esac
done < <(xfconf-query -c xfce4-desktop -l 2>/dev/null)
if (( ! found )); then xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/image-path -n -t string -s "$wallpaper"; fi
command -v xfdesktop >/dev/null 2>&1 && xfdesktop --reload >/dev/null 2>&1 || true
printf 'NED-OS wallpaper applied: %s\n' "$wallpaper"
