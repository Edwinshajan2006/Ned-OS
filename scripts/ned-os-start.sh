#!/bin/bash

sleep 3

LOG="$HOME/NED-OS/ned-os-start.log"

echo "=== NED-OS START $(date) ===" >> "$LOG"

# Plank
if ! pgrep -x plank >/dev/null; then
    plank >> "$LOG" 2>&1 &
    echo "Plank started" >> "$LOG"
else
    echo "Plank already running" >> "$LOG"
fi

# Eww
if ! eww -c "$HOME/NED-OS/eww" ping >/dev/null 2>&1; then
    eww -c "$HOME/NED-OS/eww" daemon >> "$LOG" 2>&1 &
    sleep 1
fi

if ! eww -c "$HOME/NED-OS/eww" active-windows | grep -q '^ned-bar'; then
    eww -c "$HOME/NED-OS/eww" open ned-bar >> "$LOG" 2>&1 &
    echo "Eww bar opened" >> "$LOG"
else
    echo "Eww bar already running" >> "$LOG"
fi

if ! eww -c "$HOME/NED-OS/eww" active-windows | grep -q '^ned-dock'; then
    eww -c "$HOME/NED-OS/eww" open ned-dock >> "$LOG" 2>&1 &
    echo "Eww dock opened" >> "$LOG"
else
    echo "Eww dock already running" >> "$LOG"
fi

# Conky
if ! pgrep -f "conky.*NED-OS/conky/ned-system.conf" >/dev/null; then
    conky -c "$HOME/NED-OS/conky/ned-system.conf" >> "$LOG" 2>&1 &
    echo "Conky started" >> "$LOG"
else
    echo "Conky already running" >> "$LOG"
fi
