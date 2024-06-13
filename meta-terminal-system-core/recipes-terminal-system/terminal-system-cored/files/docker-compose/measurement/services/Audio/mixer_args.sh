#!/usr/bin/env bash
set -e

alsa_list=$(dc-utils alsa list | jq -c)

IFS=$'\n'

conditional_options=

device_paths=$(echo "${alsa_list}" | jq -r ".cards[].by_path")
for device in ${device_paths}; do

  mixers=$(echo "${alsa_list}" | jq -r ".cards[] | select(.by_path == \"${device}\") | .mixer_controls // {} | keys[]")
  if [ -z "${mixers}" ]; then
    continue
  fi

  key_validation=
  for mixer in ${mixers}; do
    key_validation+="|${mixer}"
  done

  conditional_options+="{\"preconditions\":[\"DC_DEVICE_PATH=${device}\"],\"validation\":\"^((${key_validation:1})=[0-9]{1,3}%,?)*\$\"}"
done

echo "${conditional_options}" | jq -cs