#!/usr/bin/env bash
set -u

# NED-OS Bluetooth Control

if ! command -v bluetoothctl >/dev/null 2>&1; then
    printf 'ERROR: bluetoothctl is not installed.\n'
    exit 1
fi

bluetooth_status() {
    local powered
    local controller
    local discoverable
    local pairable

    controller=$(bluetoothctl show 2>/dev/null |
        awk '/^Controller / {print $2; exit}')

    powered=$(bluetoothctl show 2>/dev/null |
        awk -F': ' '/^[[:space:]]*Powered:/ {print $2; exit}')

    discoverable=$(bluetoothctl show 2>/dev/null |
        awk -F': ' '/^[[:space:]]*Discoverable:/ {print $2; exit}')

    pairable=$(bluetoothctl show 2>/dev/null |
        awk -F': ' '/^[[:space:]]*Pairable:/ {print $2; exit}')

    [ -n "${controller:-}" ] || controller="none"
    [ -n "${powered:-}" ] || powered="unknown"
    [ -n "${discoverable:-}" ] || discoverable="unknown"
    [ -n "${pairable:-}" ] || pairable="unknown"

    printf '\n'
    printf '╭──────────────────────── NED BLUETOOTH STATUS ───────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  POWER        %-47s │\n' "$(printf '%s' "$powered" | tr '[:lower:]' '[:upper:]')"
    printf '│  CONTROLLER   %-47s │\n' "$controller"
    printf '│  DISCOVERABLE %-47s │\n' "$(printf '%s' "$discoverable" | tr '[:lower:]' '[:upper:]')"
    printf '│  PAIRABLE     %-47s │\n' "$(printf '%s' "$pairable" | tr '[:lower:]' '[:upper:]')"
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'
}

bluetooth_on() {
    printf '\nNED BLUETOOTH\n\n'
    printf '  Enabling Bluetooth...\n'

    if bluetoothctl power on >/dev/null 2>&1; then
        printf '  ✓ Bluetooth enabled\n\n'
    else
        printf '  ✗ Failed to enable Bluetooth\n\n' >&2
        exit 1
    fi
}

bluetooth_off() {
    printf '\nNED BLUETOOTH\n\n'
    printf '  Disabling Bluetooth...\n'

    if bluetoothctl power off >/dev/null 2>&1; then
        printf '  ✓ Bluetooth disabled\n\n'
    else
        printf '  ✗ Failed to disable Bluetooth\n\n' >&2
        exit 1
    fi
}

bluetooth_pair() {
    printf '\n'
    printf '╭──────────────────────────── NED BLUETOOTH ──────────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  SELECT DEVICE TO PAIR                                         │\n'
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'

    mapfile -t devices < <(
        bluetoothctl devices 2>/dev/null
    )

    if [ "${#devices[@]}" -eq 0 ]; then
        printf '  No Bluetooth devices available.\n'
        printf '  Run "ned bl scan" first.\n\n'
        return 1
    fi

    local count=0

    for device in "${devices[@]}"; do
        address=$(printf '%s\n' "$device" | awk '{print $2}')
        name=$(printf '%s\n' "$device" | cut -d' ' -f3-)

        [ -n "${address:-}" ] || continue

        if [ -z "${name:-}" ] || [ "$name" = "$address" ]; then
            name="Unknown Device"
        fi

        printf '  %-3s %-19s   %s\n' \
            "$((count + 1))." \
            "$address" \
            "$name"

        count=$((count + 1))
    done

    printf '\n  0.  Cancel\n\n'

    read -r -p 'Select device: ' choice

    if [ "$choice" = "0" ]; then
        printf '\nCancelled.\n\n'
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "$count" ]; then
        printf '\nInvalid selection.\n\n' >&2
        return 2
    fi

    selected="${devices[$((choice - 1))]}"
    address=$(printf '%s\n' "$selected" | awk '{print $2}')
    name=$(printf '%s\n' "$selected" | cut -d' ' -f3-)

    [ -n "${name:-}" ] || name="Unknown Device"

    printf '\n  Pairing with %s...\n\n' "$name"

    if bluetoothctl pair "$address"; then
        printf '\n  ✓ Device paired successfully.\n\n'
    else
        printf '\n  ✗ Failed to pair with %s.\n\n' "$name" >&2
        return 1
    fi
}

bluetooth_connect() {
    printf '\n'
    printf '╭────────────────────────── NED BLUETOOTH ────────────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  SELECT DEVICE TO CONNECT                                      │\n'
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'

    mapfile -t devices < <(
        bluetoothctl devices 2>/dev/null
    )

    if [ "${#devices[@]}" -eq 0 ]; then
        printf '  No known Bluetooth devices.\n'
        printf '  Run "ned bl scan" and pair a device first.\n\n'
        return 1
    fi

    local count=0

    for device in "${devices[@]}"; do
        address=$(printf '%s\n' "$device" | awk '{print $2}')
        name=$(printf '%s\n' "$device" | cut -d' ' -f3-)

        [ -n "${address:-}" ] || continue
        [ -n "${name:-}" ] || name="Unknown Device"

        printf '  %-3s %-19s   %s\n' \
            "$((count + 1))." \
            "$address" \
            "$name"

        count=$((count + 1))
    done

    printf '\n  0.  Cancel\n\n'

    read -r -p 'Select device: ' choice

    if [ "$choice" = "0" ]; then
        printf '\nCancelled.\n\n'
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "$count" ]; then
        printf '\nInvalid selection.\n\n' >&2
        return 2
    fi

    selected="${devices[$((choice - 1))]}"
    address=$(printf '%s\n' "$selected" | awk '{print $2}')
    name=$(printf '%s\n' "$selected" | cut -d' ' -f3-)

    printf '\n  Connecting to %s...\n\n' "$name"

    if bluetoothctl connect "$address"; then
        printf '\n  ✓ Connected to %s\n\n' "$name"
    else
        printf '\n  ✗ Failed to connect to %s\n\n' "$name" >&2
        return 1
    fi
}

bluetooth_disconnect() {
    printf '\n'
    printf '╭────────────────────────── NED BLUETOOTH ────────────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  CONNECTED DEVICES                                             │\n'
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'

    mapfile -t connected < <(
        bluetoothctl devices Connected 2>/dev/null
    )

    if [ "${#connected[@]}" -eq 0 ]; then
        printf '  No connected Bluetooth devices.\n\n'
        return 0
    fi

    local count=0

    for device in "${connected[@]}"; do
        address=$(printf '%s\n' "$device" | awk '{print $2}')
        name=$(printf '%s\n' "$device" | cut -d' ' -f3-)

        [ -n "${address:-}" ] || continue
        [ -n "${name:-}" ] || name="Unknown Device"

        printf '  %-3s %-19s   %s\n' \
            "$((count + 1))." \
            "$address" \
            "$name"

        count=$((count + 1))
    done

    printf '\n  0.  Cancel\n\n'

    read -r -p 'Select device: ' choice

    if [ "$choice" = "0" ]; then
        printf '\nCancelled.\n\n'
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] ||
       [ "$choice" -lt 1 ] ||
       [ "$choice" -gt "$count" ]; then
        printf '\nInvalid selection.\n\n' >&2
        return 2
    fi

    selected="${connected[$((choice - 1))]}"
    address=$(printf '%s\n' "$selected" | awk '{print $2}')
    name=$(printf '%s\n' "$selected" | cut -d' ' -f3-)

    printf '\n  Disconnecting from %s...\n\n' "$name"

    if bluetoothctl disconnect "$address"; then
        printf '\n  ✓ Disconnected from %s\n\n' "$name"
    else
        printf '\n  ✗ Failed to disconnect from %s\n\n' "$name" >&2
        return 1
    fi
}

bluetooth_devices() {
    printf '\n'
    printf '╭────────────────────────── NED BLUETOOTH ────────────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  REMEMBERED DEVICES                                            │\n'
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'

    mapfile -t devices < <(
        bluetoothctl devices 2>/dev/null
    )

    if [ "${#devices[@]}" -eq 0 ]; then
        printf '  No remembered devices.\n\n'
        return 0
    fi

    local found=0

    for device in "${devices[@]}"; do
        address=$(printf '%s\n' "$device" | awk '{print $2}')
        name=$(printf '%s\n' "$device" | cut -d' ' -f3-)

        [ -n "${address:-}" ] || continue

        if [ -z "${name:-}" ] || [ "$name" = "$address" ]; then
            name="Unknown Device"
        fi

        printf '  %-3s %-19s   %s\n' \
            "$((found + 1))." \
            "$address" \
            "$name"

        found=$((found + 1))
    done

    printf '\n'
}

bluetooth_erase() {
    printf '\n'
    printf '╭────────────────────────── NED BLUETOOTH ────────────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  FORGETTING ALL REMEMBERED DEVICES...                          │\n'
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'

    mapfile -t devices < <(
        bluetoothctl devices 2>/dev/null |
        awk '/^Device / {print $2}'
    )

    if [ "${#devices[@]}" -eq 0 ]; then
        printf '  No remembered devices found.\n\n'
        return 0
    fi

    local failed=0
    local removed=0

    for address in "${devices[@]}"; do
        if bluetoothctl remove "$address" >/dev/null 2>&1; then
            removed=$((removed + 1))
        else
            failed=1
        fi
    done

    if [ "$failed" -eq 0 ]; then
        printf '  ✓ Forgotten %s device(s)\n\n' "$removed"
    else
        printf '  ⚠ Forgotten %s device(s), but some could not be removed.\n\n' "$removed"
        return 1
    fi
}

bluetooth_scan() {
    printf '\n'
    printf '╭──────────────────────────── NED BLUETOOTH ──────────────────────╮\n'
    printf '│                                                                 │\n'
    printf '│  SCANNING FOR BLUETOOTH DEVICES...                             │\n'
    printf '│                                                                 │\n'
    printf '╰─────────────────────────────────────────────────────────────────╯\n\n'

    if ! bluetoothctl power on >/dev/null 2>&1; then
        printf '  ✗ Unable to power on Bluetooth.\n\n' >&2
        exit 1
    fi

    printf '  Scanning for 10 seconds...\n\n'

    bluetoothctl scan on >/dev/null 2>&1 &
    local scan_pid=$!

    sleep 10

    bluetoothctl scan off >/dev/null 2>&1 || true
    kill "$scan_pid" 2>/dev/null || true
    wait "$scan_pid" 2>/dev/null || true

    printf '  Nearby devices:\n\n'

    mapfile -t devices < <(
        bluetoothctl devices 2>/dev/null
    )

    local found=0

    for device in "${devices[@]}"; do
        address=$(printf '%s\n' "$device" | awk '{print $2}')

        [ -n "${address:-}" ] || continue

        info=$(bluetoothctl info "$address" 2>/dev/null || true)

        if printf '%s\n' "$info" | grep -q '^Device '; then
            name=$(printf '%s\n' "$info" |
                awk -F': ' '/^[[:space:]]*(Name|Alias):/ {
                    print $2
                    exit
                }')

            [ -n "${name:-}" ] || name="Unknown Device"

            printf '  %-3s %-19s   %s\n' \
                "$((found + 1))." \
                "$address" \
                "$name"

            found=$((found + 1))
        fi
    done

    if [ "$found" -eq 0 ]; then
        printf '  No Bluetooth devices found.\n'
    fi

    printf '\n'
}

usage() {
    cat <<'HELP'

NED-OS Bluetooth

Usage: ned bl [command]

Commands:
  bl              Scan for Bluetooth devices
  bl scan         Scan for nearby devices
  bl on           Turn Bluetooth on
  bl off          Turn Bluetooth off
  bl status       Show Bluetooth status
  bl devices      Show remembered devices
  bl pair         Pair with a Bluetooth device
  bl connect       Connect to a Bluetooth device
  bl disconnect    Disconnect a Bluetooth device
  bl erase         Forget all remembered devices

HELP
}

case "${1:-scan}" in
    scan)
        bluetooth_scan
        ;;
    on)
        bluetooth_on
        ;;
    off)
        bluetooth_off
        ;;
    status)
        bluetooth_status
        ;;
    devices)
        bluetooth_devices
        ;;
    pair)
        bluetooth_pair
        ;;
    connect)
        bluetooth_connect
        ;;
    disconnect)
        bluetooth_disconnect
        ;;
    erase)
        bluetooth_erase
        ;;
    help|-h|--help)
        usage
        ;;
    *)
        printf 'Unknown Bluetooth command: %s\n' "$1" >&2
        usage >&2
        exit 2
        ;;
esac
