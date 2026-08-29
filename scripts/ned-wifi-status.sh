#!/usr/bin/env bash

if ! command -v nmcli >/dev/null 2>&1; then
    echo "ERROR: nmcli is not installed."
    exit 1
fi

radio=$(nmcli radio wifi 2>/dev/null)
device=$(nmcli -t -f DEVICE,TYPE device 2>/dev/null | awk -F: '$2=="wifi" {print $1; exit}')

state="disconnected"
ssid="none"
signal="--"

if [ -n "$device" ]; then
    state=$(nmcli -t -f DEVICE,STATE device 2>/dev/null |
        awk -F: -v d="$device" '$1==d {print $2; exit}')

    ssid=$(nmcli -t -f DEVICE,CONNECTION device 2>/dev/null |
        awk -F: -v d="$device" '$1==d {print $2; exit}')

    signal=$(nmcli -t -f IN-USE,SIGNAL device wifi list 2>/dev/null |
        awk -F: '$1=="*" {print $2; exit}')
fi

[ -n "$device" ] || device="none"
[ -n "$state" ] || state="disconnected"
[ -n "$ssid" ] || ssid="none"
[ -n "$signal" ] || signal="--"

echo
echo "╭──────────────────────── NED WI-FI STATUS ────────────────────────╮"
echo "│                                                                 │"
printf '│  POWER       %-48s │\n' "$(echo "$radio" | tr '[:lower:]' '[:upper:]')"
printf '│  INTERFACE   %-48s │\n' "$device"
printf '│  STATE       %-48s │\n' "$state"
printf '│  NETWORK     %-48s │\n' "$ssid"
printf '│  SIGNAL      %-48s │\n' "${signal}%"
echo "│                                                                 │"
echo "╰─────────────────────────────────────────────────────────────────╯"
echo
