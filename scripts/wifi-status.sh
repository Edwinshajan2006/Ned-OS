#!/bin/bash

wifi=$(nmcli -t -f IN-USE,SIGNAL dev wifi 2>/dev/null | awk -F: '$1=="*"{print $2"%"; exit}')

if [ -n "$wifi" ]; then
    echo "WIFI $wifi"
else
    echo "WIFI --"
fi
