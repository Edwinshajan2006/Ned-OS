#!/bin/bash

volume=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null)

if echo "$volume" | grep -q MUTED; then
    echo "VOL MUTED"
else
    percent=$(echo "$volume" | awk '{printf "%d%%", $2 * 100}')
    echo "VOL $percent"
fi
