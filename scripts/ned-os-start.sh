#!/bin/bash

sleep 3

# Disable the unwanted XFCE panel.
xfce4-panel -q >/dev/null 2>&1 || true

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

# Reserve 30px at the top for the NED bar.
# Wait until the Eww window exists, then apply the X11 strut.
for i in {1..20}; do
    NED_BAR_ID="$(wmctrl -l | awk '/Eww - ned-bar$/ {print $1; exit}')"
    if [ -n "$NED_BAR_ID" ]; then
        xprop -id "$NED_BAR_ID" \
            -f _NET_WM_STRUT_PARTIAL 32c \
            -set _NET_WM_STRUT_PARTIAL "0,0,30,0,0,0,0,0,0,1919,0,0" \
            >> "$LOG" 2>&1
        echo "NED top bar reserved 30px" >> "$LOG"
        break
    fi
    sleep 0.25
done

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
