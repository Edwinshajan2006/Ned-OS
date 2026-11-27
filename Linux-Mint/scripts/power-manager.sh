#!/usr/bin/env bash
set -u

usage() {
    cat <<'EOF'
NED-OS Power Management

Usage:
  ned power save
  ned power balanced
  ned power performance
  ned power status
  ned power shutdown
  ned power reboot
  ned power lock

Power profiles:
  save         Enable power-saver mode
  balanced     Enable balanced mode
  performance  Enable performance mode
  status       Show current power profile
EOF
}

# Check for powerprofilesctl
if ! command -v powerprofilesctl >/dev/null 2>&1; then
    printf 'NED: powerprofilesctl is not installed.\n' >&2
    printf 'NED: Install power-profiles-daemon to enable power profiles.\n' >&2
    exit 1
fi

case "${1:-status}" in

    save)
        powerprofilesctl set power-saver
        printf 'NED: Power Saver mode enabled.\n'
        ;;

    balanced)
        powerprofilesctl set balanced
        printf 'NED: Balanced mode enabled.\n'
        ;;

    performance)
        powerprofilesctl set performance
        printf 'NED: Performance mode enabled.\n'
        ;;

    status)
        printf 'NED-OS POWER STATUS\n'
        printf '%s\n' '-------------------'
        printf 'Profile: %s\n' "$(powerprofilesctl get)"
        ;;

    shutdown)
        if zenity --question \
            --title="NED-OS Power" \
            --text="Shut down NED-OS?" \
            --ok-label="Confirm" \
            --cancel-label="Cancel"; then
            systemctl poweroff
        fi
        ;;

    reboot)
        if zenity --question \
            --title="NED-OS Power" \
            --text="Restart NED-OS?" \
            --ok-label="Confirm" \
            --cancel-label="Cancel"; then
            systemctl reboot
        fi
        ;;

    lock)
        LC_ALL=C.UTF-8 i3lock
        ;;

    help|-h|--help)
        usage
        ;;

    *)
        printf 'NED: Unknown power action: %s\n\n' "$1" >&2
        usage >&2
        exit 2
        ;;

esac
