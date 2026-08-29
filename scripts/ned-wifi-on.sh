#!/usr/bin/env bash

if ! command -v nmcli >/dev/null 2>&1; then
    echo "ERROR: nmcli is not installed."
    exit 1
fi

echo
echo "NED WI-FI"
echo
echo "  Enabling Wi-Fi..."

if nmcli radio wifi on >/dev/null 2>&1; then
    echo "  ✓ Wi-Fi enabled"
else
    echo "  ✗ Failed to enable Wi-Fi"
    exit 1
fi

echo
