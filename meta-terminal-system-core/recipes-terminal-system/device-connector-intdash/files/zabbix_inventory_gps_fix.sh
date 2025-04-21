#!/bin/bash
set -e -o pipefail

function collect_content_gps() {
  set -e -o pipefail

  local journal_output
  journal_output="$(journalctl -u docker -o cat --no-pager --since '10 seconds ago')"

  # [UBX-STATUS] is logged every 3 seconds by device-connector-intdash
  local gps_ubx="$(echo "$journal_output" | grep '\[UBX-STATUS\]' | sed -n 's/.*\[UBX-STATUS\] \({.*}\).*/\1/p' | tail -n 1)"

  # nmea-packet(gps) is logged every 3 seconds by device-connector-intdash
  local gps_nmea_mode="$(echo "$journal_output" | grep 'nmea-packet(gps)' | sed -n 's/^.*nmea-packet(gps):.*<mode:\([NADE]\)>.*/\1/p' | tail -n 1)"
  local gps_nmea_fix="$(echo "$journal_output" | grep 'nmea-packet(gps)' | sed -n 's/^.*nmea-packet(gps):.*<fix:\([0-9a-zA-Z _-]*\)>.*/\1/p' | tail -n 1)"

  if [ -n "$gps_ubx" ]; then
    if [ -n "$gps_nmea_mode" ] && [ -n "$gps_nmea_fix" ]; then
      echo "${gps_ubx/%\}/,} \"nmea\": {\"mode\": \"$gps_nmea_mode\", \"fix\": \"$gps_nmea_fix\"}}"
    else
      echo "${gps_ubx}"
    fi
  else
    if [ -n "$gps_nmea_mode" ] && [ -n "$gps_nmea_fix" ]; then
      echo "{\"nmea\": {\"mode\": \"$gps_nmea_mode\", \"fix\": \"$gps_nmea_fix\"}}"
    else
      echo "{}"
    fi
  fi
}

export -f collect_content_gps

gps=$(collect_content_gps)
echo "${gps}"