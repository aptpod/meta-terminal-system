#!/usr/bin/env bash
set -e

interfaces="[]"
for type in can vcan vxcan; do
  interface=$(ip link show type ${type} | sed -n 's/^[0-9]\+: \(.*\):.*$/\1/p')
  interfaces+=$(echo "${interface}" | jq -Rcs 'split("\n")[:-1] | map(select(length > 0))')
done

echo "${interfaces}" | jq -cs 'add'