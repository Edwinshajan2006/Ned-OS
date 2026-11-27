#!/usr/bin/env bash
set -u

# NED-OS Wi-Fi Control

if ! command -v nmcli >/dev/null 2>&1; then
    printf 'ERROR: nmcli is not installed.\n'
    exit 1
fi

wifi_status() {
    local radio
    local device
    local state
    local ssid
    local signal

    radio=$(nmcli radio wifi 2>/dev/null || printf 'unknown')
    device=$(nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null |
        awk -F: '$2=="wifi" {print $1; exit}')

    state=$(nmcli -t -f DEVICE,STATE device 2>/dev/null |
        awk -F: -v d="$device" '$1==d {print $2; exit}')

    ssid=$(nmcli -t -f DEVICE,CONNECTION device 2>/dev/null |
        awk -F: -v d="$device" '$1==d {print $2; exit}')

    signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list 2>/dev/null |
        awk -F: '$1=="*" {print $2; exit}')

    [ -n "${device:-}" ] || device="none"
    [ -n "${state:-}" ] || state="disconnected"
    [ -n "${ssid:-}" ] || ssid="none"
    [ -n "${signal:-}" ] || signal="--"

    printf '\n'
    printf '╭──────────────────────── NED WI-FI STATUS ────────────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  POWER       %-48s │\n' "$(printf '%s' "$radio" | tr '[:lower:]' '[:upper:]')"
    printf '│  INTERFACE   %-48s │\n' "$device"
    printf '│  STATE       %-48s │\n' "$state"
    printf '│  NETWORK     %-48s │\n' "$ssid"
    printf '│  SIGNAL      %-48s │\n' "${signal}%"
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'
}

wifi_on() {
    printf '\nNED WI-FI\n\n'
    printf '  Enabling Wi-Fi...\n'

    if nmcli radio wifi on >/dev/null 2>&1; then
        printf '  ✓ Wi-Fi enabled\n\n'
    else
        printf '  ✗ Failed to enable Wi-Fi\n\n' >&2
        exit 1
    fi
}

wifi_off() {
    printf '\nNED WI-FI\n\n'
    printf '  Disabling Wi-Fi...\n'

    if nmcli radio wifi off >/dev/null 2>&1; then
        printf '  ✓ Wi-Fi disabled\n\n'
    else
        printf '  ✗ Failed to disable Wi-Fi\n\n' >&2
        exit 1
    fi
}

wifi_disconnect() {
    local device

    device=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null |
        awk -F: '$2=="wifi" {print $1; exit}')

    if [ -z "${device:-}" ]; then
        printf 'No Wi-Fi interface found.\n'
        exit 1
    fi

    printf '\nNED WI-FI\n\n'
    printf '  Disconnecting %s...\n' "$device"

    if nmcli device disconnect "$device" >/dev/null 2>&1; then
        printf '  ✓ Wi-Fi disconnected\n\n'
    else
        printf '  ✗ Failed to disconnect Wi-Fi\n\n' >&2
        exit 1
    fi
}

wifi_scan() {
    printf '\n'
    printf '╭────────────────────────────── NED WI-FI ──────────────────────────────╮\n'
    printf '│                                                                      │\n'
    printf '│  SCANNING FOR WI-FI NETWORKS...                                     │\n'
    printf '│                                                                      │\n'

    nmcli device wifi rescan >/dev/null 2>&1 || true
    sleep 2

    mapfile -t networks < <(
        nmcli -t --fields SSID,SIGNAL,CHAN,SECURITY \
            --escape yes device wifi list 2>/dev/null |
        awk -F: 'NF >= 4 && $1 != "" {
            security=$4
            if (security == "--" || security == "") security="OPEN"
            print $1 "\t" $2 "\t" $3 "\t" security
        }'
    )

    if [ "${#networks[@]}" -eq 0 ]; then
        printf '│  No Wi-Fi networks found.                                          │\n'
        printf '│                                                                      │\n'
        printf '╰──────────────────────────────────────────────────────────────────────╯\n\n'
        exit 1
    fi

    printf '│  %-3s %-25s %-9s %-10s %-15s │\n' "#" "SSID" "SIGNAL" "CHANNEL" "SECURITY"
    printf '│  ──────────────────────────────────────────────────────────────────  │\n'

    for i in "${!networks[@]}"; do
        IFS=$'\t' read -r ssid signal channel security <<< "${networks[$i]}"

        display_ssid="$ssid"
        [ "${#display_ssid}" -le 25 ] ||
            display_ssid="${display_ssid:0:22}..."

        printf '│  %-3s %-25s %-9s %-10s %-15s │\n' \
            "$((i + 1))" \
            "$display_ssid" \
            "${signal}%" \
            "$channel" \
            "$security"
    done

    printf '│                                                                      │\n'
    printf '│  0   Cancel                                                         │\n'
    printf '│                                                                      │\n'
    printf '╰──────────────────────────────────────────────────────────────────────╯\n\n'

    read -r -p 'Select network: ' choice

    if [ "$choice" = "0" ]; then
        printf 'Cancelled.\n'
        exit 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "${#networks[@]}" ]; then
        printf 'Invalid selection.\n' >&2
        exit 2
    fi

    selected="${networks[$((choice - 1))]}"
    IFS=$'\t' read -r ssid signal channel security <<< "$selected"

    printf '\nSelected: %s\n' "$ssid"

    if [ "$security" = "OPEN" ]; then
        printf 'Open network detected.\n'
        printf 'Connecting...\n\n'

        if nmcli device wifi connect "$ssid"; then
            printf '\n✓ Connected to %s\n\n' "$ssid"
        else
            printf '\n✗ Failed to connect to %s\n\n' "$ssid" >&2
            exit 1
        fi
    else
        printf 'Password for "%s": ' "$ssid"
        read -r -s password
        printf '\n\nConnecting...\n'

        if nmcli device wifi connect "$ssid" password "$password"; then
            printf '\n✓ Connected to %s\n\n' "$ssid"
        else
            printf '\n✗ Failed to connect to %s\n\n' "$ssid" >&2
            exit 1
        fi
    fi
}

usage() {
    cat <<'HELP'

NED-OS Wi-Fi

Usage: ned wifi [command]

Commands:
  wifi              Scan and connect to a Wi-Fi network
  wifi scan         Scan available networks
  wifi on           Turn Wi-Fi on
  wifi off          Turn Wi-Fi off
  wifi status       Show Wi-Fi status
  wifi disconnect   Disconnect from Wi-Fi

HELP
}

case "${1:-scan}" in
    scan)
        wifi_scan
        ;;
    on)
        wifi_on
        ;;
    off)
        wifi_off
        ;;
    status)
        wifi_status
        ;;
    disconnect)
        wifi_disconnect
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        printf 'Unknown Wi-Fi command: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
esac
