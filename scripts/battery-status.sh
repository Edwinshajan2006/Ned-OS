#!/bin/bash

BAT="/sys/class/power_supply/BAT0"

if [ -f "$BAT/capacity" ]; then
    capacity=$(cat "$BAT/capacity")
    status=$(cat "$BAT/status")

    case "$status" in
        Charging)
            echo "BAT $capacity%+"
            ;;
        Full)
            echo "BAT $capacity%"
            ;;
        Discharging)
            echo "BAT $capacity%"
            ;;
        *)
            echo "BAT $capacity%"
            ;;
    esac
else
    echo "BAT --"
fi
