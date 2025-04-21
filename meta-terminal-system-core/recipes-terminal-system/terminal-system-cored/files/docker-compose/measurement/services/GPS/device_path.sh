#!/usr/bin/env bash
set -e

# Find device paths
device_paths=($(find /dev/tty* /dev/serial/by-id/* /dev/serial/by-path/* 2>/dev/null))

# Remove gpsd device paths
source /etc/default/gpsd || true
if [ -n "$DEVICES" ]; then
  IFS=' ' read -r -a devices_to_remove <<< "$DEVICES"
  for device in "${devices_to_remove[@]}"; do
    device_paths=("${device_paths[@]/$device}")
  done
fi

# Print the remaining device paths as a JSON array
echo -n "${device_paths[@]}" | jq -R -s -c 'split(" ") | map(select(length > 0))'