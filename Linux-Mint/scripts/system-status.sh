#!/usr/bin/env bash
# Read-only NED-OS system snapshot. Optional hardware is always best-effort.
set -u

cpu_usage() {
    local start end
    start=$(awk '/^cpu / { print $2+$3+$4+$5+$6+$7+$8, $5; exit }' /proc/stat 2>/dev/null) || { printf 'n/a'; return; }
    sleep 0.2
    end=$(awk '/^cpu / { print $2+$3+$4+$5+$6+$7+$8, $5; exit }' /proc/stat 2>/dev/null) || { printf 'n/a'; return; }
    local total_a idle_a total_b idle_b total_delta idle_delta
    read -r total_a idle_a <<<"$start"; read -r total_b idle_b <<<"$end"
    total_delta=$((total_b - total_a)); idle_delta=$((idle_b - idle_a))
    (( total_delta > 0 )) && printf '%s%%' "$((100 * (total_delta - idle_delta) / total_delta))" || printf 'n/a'
}
memory_usage() { free -h 2>/dev/null | awk '/^Mem:/ { printf "%s / %s", $3, $2; exit }' || printf 'n/a'; }
disk_usage() { df -h / 2>/dev/null | awk 'NR == 2 { printf "%s / %s (%s)", $3, $2, $5; exit }' || printf 'n/a'; }
uptime_value() { uptime -p 2>/dev/null | sed 's/^up //' || printf 'n/a'; }
network_value() {
    local interface ip
    interface=$(ip route show default 2>/dev/null | awk 'NR == 1 { print $5 }')
    [[ -n "${interface:-}" ]] || { printf 'offline'; return; }
    ip=$(ip -4 -o addr show dev "$interface" scope global 2>/dev/null | awk 'NR == 1 { print $4 }')
    printf '%s%s' "$interface" "${ip:+ ($ip)}"
}
battery_value() {
    local battery capacity status
    for battery in /sys/class/power_supply/BAT*; do
        [[ -r "$battery/capacity" ]] || continue
        capacity=$(<"$battery/capacity"); status=$(<"$battery/status")
        printf '%s%% (%s)' "$capacity" "$status"; return
    done
    printf 'not present'
}
temperature_value() {
    local zone temp
    for zone in /sys/class/thermal/thermal_zone*/temp; do
        [[ -r "$zone" ]] || continue
        temp=$(<"$zone")
        [[ "$temp" =~ ^[0-9]+$ ]] && printf '%s°C' "$((temp / 1000))" && return
    done
    printf 'unavailable'
}
load_value() { awk '{ print $1 ", " $2 ", " $3 }' /proc/loadavg 2>/dev/null || printf 'n/a'; }

printf 'NED-OS SYSTEM STATUS\n'
printf '%-14s %s\n' 'CPU' "$(cpu_usage)" 'Memory' "$(memory_usage)" 'Disk' "$(disk_usage)" 'Load (1/5/15)' "$(load_value)" 'Uptime' "$(uptime_value)" 'Battery' "$(battery_value)" 'Temperature' "$(temperature_value)" 'Network' "$(network_value)"
