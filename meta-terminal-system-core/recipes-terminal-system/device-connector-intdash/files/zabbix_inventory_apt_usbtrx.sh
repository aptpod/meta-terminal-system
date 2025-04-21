#!/bin/bash
set -e -o pipefail

declare -a serials=()

function collect_content_firmware_apt_usbtrx() {
  set -e -o pipefail

  local device_path="$1"
  local device_name
  local version
  local sync_pulse
  local product
  local serial

  if [ ! -e "$device_path" ]; then
    return
  fi

  # Get by sysfs
  device_name=$(basename "$device_path")
  version=$(cat "/sys/class/usbmisc/$device_name/device/firmware_version")

  # Get by udevadm
  sync_pulse=$(cat "/sys/class/usbmisc/$device_name/device/sync_pulse")
  product=$(udevadm info --query=all --name="$device_path" | grep 'ID_MODEL=' | awk -F= '{print $2}')
  serial=$(udevadm info --query=all --name="$device_path" | grep 'ID_SERIAL_SHORT=' | awk -F= '{print $2}')

  # Check if serial is already registered
  for registered in "${serials[@]}"; do
    if [ "$registered" == "$serial" ]; then
      return
    fi
  done

  echo -n "{\"product\":\"$product\",\"serial\":\"$serial\",\"sync_pulse\":\"$sync_pulse\",\"version\":\"$version\"},"
}

export -f collect_content_firmware_apt_usbtrx

apt_usbtrx_list+=$(find /dev -mindepth 1 -maxdepth 1 -name "${1/all/aptUSB*}" -exec bash -c 'collect_content_firmware_apt_usbtrx "$0"' {} \;)
echo "[${apt_usbtrx_list/%,/}]"