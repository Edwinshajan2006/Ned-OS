#!/usr/bin/env bash

if ! command -v nmcli >/dev/null 2>&1; then
    echo "ERROR: nmcli is not installed."
    exit 1
fi

echo
echo "NED WI-FI"
echo
echo "  Disabling Wi-Fi..."

if nmcli radio wifi off >/dev/null 2>&1; then
    echo "  ✓ Wi-Fi disabled"
else
    echo "  ✗ Failed to disable Wi-Fi"
    exit 1
fi

echo
