#!/usr/bin/env bash
set -u
root_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
config="$root_dir/config/fastfetch/config.jsonc"
if command -v fastfetch >/dev/null 2>&1 && [[ -f "$config" ]]; then exec fastfetch --config "$config"; fi
printf 'NED-OS information is unavailable: fastfetch or its configuration is missing.\n' >&2
exit 1
