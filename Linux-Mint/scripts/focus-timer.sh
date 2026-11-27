#!/bin/bash

STATE_DIR="$HOME/.config/ned-os"
PIDFILE="$STATE_DIR/focus.pid"
ENDTIME="$STATE_DIR/focus-end"
TIMERPID="$STATE_DIR/focus-timer.pid"

DEFAULT_MINUTES=25

start_focus() {
    local minutes="${1:-$DEFAULT_MINUTES}"

    if ! [[ "$minutes" =~ ^[0-9]+$ ]] || [ "$minutes" -le 0 ]; then
        echo "Usage: ned focus start [minutes]"
        exit 1
    fi

    if [ -f "$PIDFILE" ]; then
        echo "NED FOCUS is already active."
        exit 1
    fi

    mkdir -p "$STATE_DIR"

    local duration=$((minutes * 60))
    local end_time=$(( $(date +%s) + duration ))

    echo "$end_time" > "$ENDTIME"

    (
        echo $$ > "$PIDFILE"

        while [ -f "$PIDFILE" ]; do
            NOW=$(date +%s)
            END=$(cat "$ENDTIME" 2>/dev/null)

            if [ -z "$END" ]; then
                break
            fi

            if [ "$NOW" -ge "$END" ]; then
                rm -f "$PIDFILE" "$ENDTIME" "$TIMERPID"
                exit 0
            fi

            sleep 1
        done
    ) >/dev/null 2>&1 &

    echo $! > "$TIMERPID"

    disown "$!" 2>/dev/null

    # Give the background process a moment to register.
    sleep 0.2

    exit 0
}

stop_focus() {
    if [ ! -f "$PIDFILE" ]; then
        echo "NED FOCUS is not running."
        exit 0
    fi

    rm -f "$PIDFILE" "$ENDTIME"

    if [ -f "$TIMERPID" ]; then
        kill "$(cat "$TIMERPID")" 2>/dev/null
        rm -f "$TIMERPID"
    fi

    echo "NED FOCUS stopped."
}

status_focus() {
    if [ ! -f "$PIDFILE" ]; then
        echo "NED FOCUS: OFF"
        exit 0
    fi

    if [ ! -f "$ENDTIME" ]; then
        echo "NED FOCUS: ERROR — missing timer state"
        exit 1
    fi

    NOW=$(date +%s)
    END=$(cat "$ENDTIME")
    REMAINING=$((END - NOW))

    if [ "$REMAINING" -le 0 ]; then
        echo "NED FOCUS: FINISHED"
        rm -f "$PIDFILE" "$ENDTIME" "$TIMERPID"
        exit 0
    fi

    MINUTES_LEFT=$((REMAINING / 60))
    SECONDS_LEFT=$((REMAINING % 60))

    echo "NED FOCUS: ACTIVE"
    printf "REMAINING: %02d:%02d\n" \
        "$MINUTES_LEFT" "$SECONDS_LEFT"
}

case "${1:-start}" in
    start)
        start_focus "${2:-$DEFAULT_MINUTES}"
        ;;
    stop)
        stop_focus
        ;;
    status)
        status_focus
        ;;
    *)
        echo "Usage:"
        echo "  ned focus start [minutes]"
        echo "  ned focus stop"
        echo "  ned focus status"
        ;;
esac
