#!/bin/bash
set -e -o pipefail

POWERMANAGE_LOCK_PATH="/var/lock/edgeplant_powermanage.lock"
POWERMANAGE_TIMEOUT=10

function edgeplant_powermanage_cmd() {
  set -e -o pipefail

  local cmd="$1"
  flock --timeout $POWERMANAGE_TIMEOUT $POWERMANAGE_LOCK_PATH -c "/usr/bin/timeout 1 /usr/bin/edgeplant-l4t/edgeplant_powermanage $cmd" || true
}

export -f edgeplant_powermanage_cmd


dump="$(edgeplant_powermanage_cmd dump)"
version="$(echo "$dump" | grep 'version: ' | sed -e 's/version: \(.*\)/\1/g')"
dump=$(echo "$dump" | tr '\n' ' ') 
echo "{\"version\":\"$version\",\"dump\":\"$dump\"}"
