#!/usr/bin/env bash
set -u

usage() {
    printf 'Usage: ned-power.sh {shutdown|reboot|lock}\n'
}

confirm() {
    zenity --question \
        --title="NED-OS Power" \
        --text="$1" \
        --ok-label="Confirm" \
        --cancel-label="Cancel"
}

case "${1:-}" in
    shutdown)
        if confirm "Shut down NED-OS?"; then
            systemctl poweroff
        fi
        ;;
    reboot)
        if confirm "Restart NED-OS?"; then
            systemctl reboot
        fi
        ;;
    lock)
        LC_ALL=C.UTF-8 i3lock
        ;;
    *)
        usage >&2
        exit 2
        ;;
esac
