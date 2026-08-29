#!/bin/bash

case "$1" in
    0) wmctrl -s 0 ;;
    1) wmctrl -s 1 ;;
    2) wmctrl -s 2 ;;
    3) wmctrl -s 3 ;;
esac
