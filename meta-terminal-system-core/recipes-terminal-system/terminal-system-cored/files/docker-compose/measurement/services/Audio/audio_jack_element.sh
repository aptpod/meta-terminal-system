#!/usr/bin/env bash
set -e

alsa_list=$(dc-utils alsa list | jq -c)

device_paths=$(echo "${alsa_list}" | jq -r ".cards[].by_path")

IFS=$'\n'
conditional_options=
for device in ${device_paths}; do
  conditional_options+=$(echo "${alsa_list}" | jq -c "{preconditions:[\"DC_DEVICE_PATH=${device}\"], options:(.cards[] | select(.by_path == \"${device}\") | .jack_elements // {} | keys | . += [\"\"])}")
done

echo "${conditional_options}" | jq -cs