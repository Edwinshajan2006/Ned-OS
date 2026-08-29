#!/bin/bash

# NED-OS workspace shortcuts
# Super + 1 → DEV
# Super + 2 → WEB
# Super + 3 → MEDIA
# Super + 4 → SYS

case "$1" in
    1) wmctrl -s 0 ;;
    2) wmctrl -s 1 ;;
    3) wmctrl -s 2 ;;
    4) wmctrl -s 3 ;;
esac
