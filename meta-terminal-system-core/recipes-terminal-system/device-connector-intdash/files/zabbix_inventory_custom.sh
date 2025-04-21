#!/bin/bash
set -e -o pipefail

function collect_content_custom() {
  set -e -o pipefail

  if [ -s "$1" ]; then
    echo -n "\"$(basename "$1")\":$(cat "$1"),"
  fi
}

export -f collect_content_custom

custom_list+=$(find /var/run/device-inventory/custom.d -mindepth 1 -maxdepth 1 -type f -name "${1/all/*}" -exec bash -c 'collect_content_custom "$0"' {} \;)
echo "{${custom_list/%,/}}"