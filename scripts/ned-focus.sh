#!/bin/bash

PIDFILE="/tmp/ned-focus.pid"
STARTFILE="/tmp/ned-focus-start"
TIMERPID="/tmp/ned-focus-timer.pid"

start_focus() {

    if [ -f "$PIDFILE" ]; then
        echo "NED FOCUS is already active."
        exit 1
    fi

    echo $$ > "$PIDFILE"
    date +%s > "$STARTFILE"

    echo
    echo "================================"
    echo "        NED FOCUS MODE"
    echo "================================"
    echo
    echo "Focus mode started."
    echo
    echo "Existing Chrome tabs are protected."
    echo "New tabs will be rejected."
    echo "Closed tabs will be restored."
    echo
    echo "Stop with:"
    echo "  ned focus stop"
    echo

    (
        while [ -f "$PIDFILE" ]; do

            START=$(cat "$STARTFILE")
            NOW=$(date +%s)
            ELAPSED=$((NOW - START))

            HOURS=$((ELAPSED / 3600))
            MINUTES=$(((ELAPSED % 3600) / 60))
            SECONDS=$((ELAPSED % 60))

            printf "\rNED FOCUS  %02d:%02d:%02d" \
                "$HOURS" "$MINUTES" "$SECONDS"

            sleep 1
        done
    ) &

    echo $! > "$TIMERPID"

    while [ -f "$PIDFILE" ]; do
        sleep 2
    done
}

stop_focus() {

    if [ ! -f "$PIDFILE" ]; then
        echo "NED FOCUS is not running."
        exit 0
    fi

    rm -f "$PIDFILE"
    rm -f "$STARTFILE"

    if [ -f "$TIMERPID" ]; then
        kill "$(cat "$TIMERPID")" 2>/dev/null
        rm -f "$TIMERPID"
    fi

    echo
    echo "NED FOCUS stopped."
}

status_focus() {

    if [ -f "$PIDFILE" ]; then

        START=$(cat "$STARTFILE")
        NOW=$(date +%s)
        ELAPSED=$((NOW - START))

        HOURS=$((ELAPSED / 3600))
        MINUTES=$(((ELAPSED % 3600) / 60))
        SECONDS=$((ELAPSED % 60))

        echo "NED FOCUS: ACTIVE"
        printf "TIME: %02d:%02d:%02d\n" \
            "$HOURS" "$MINUTES" "$SECONDS"

    else
        echo "NED FOCUS: OFF"
    fi
}

case "${1:-start}" in

    start)
        start_focus
        ;;

    stop)
        stop_focus
        ;;

    status)
        status_focus
        ;;

    *)
        echo "Usage:"
        echo "  ned focus"
        echo "  ned focus stop"
        echo "  ned focus status"
        ;;

esac
