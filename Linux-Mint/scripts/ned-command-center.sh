#!/usr/bin/env bash
set -u

root_dir="${NED_OS_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
scripts="$root_dir/scripts"

show_help() {
    cat <<'HELP'
NED-OS COMMAND CENTER

Usage:
  ned <command>

System:
  info              Show system information
  status            Show system status
  doctor            Run diagnostics

Network:
  wifi [command]    Manage Wi-Fi
  bluetooth [cmd]   Manage Bluetooth

Appearance:
  wallpaper         Set the XFCE wallpaper

Power:
  power <action>    Manage power profiles and session actions
  shutdown          Shut down
  restart           Reboot
  lock              Lock the session

Focus:
  focus [start|stop|status] [minutes]
  focus start 25    Start a 25-minute focus session

Other:
  help              Show this help
HELP
}

case "${1:-help}" in
    info)       exec "$scripts/system-information.sh" ;;
    status)     exec "$scripts/system-status.sh" ;;
    doctor)     exec "$scripts/system-diagnostics.sh" ;;
    wallpaper)  exec "$scripts/xfce-wallpaper-manager.sh" "${@:2}" ;;
    wifi)       exec "$scripts/wifi-manager.sh" "${@:2}" ;;
    bluetooth|bl) exec "$scripts/bluetooth-manager.sh" "${@:2}" ;;
    power)      exec "$scripts/power-manager.sh" "${@:2}" ;;
    shutdown)   exec "$scripts/power-manager.sh" shutdown ;;
    restart)    exec "$scripts/power-manager.sh" reboot ;;
    lock)       exec "$scripts/power-manager.sh" lock ;;
    kill)
        pkill -f chrome 2>/dev/null || true
        pkill -f chromium 2>/dev/null || true
        echo "Browser processes closed."
        ;;
    focus)      exec "$scripts/focus-timer.sh" "${2:-start}" "${3:-}" ;;
    help|--help|-h) show_help ;;
    *)
        echo "Unknown command: $1" >&2
        show_help
        exit 1
        ;;
esac
