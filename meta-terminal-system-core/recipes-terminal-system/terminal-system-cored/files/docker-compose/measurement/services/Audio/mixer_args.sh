#!/usr/bin/env bash
set -e

alsa_list=$(dc-utils alsa list | jq -c)

IFS=$'\n'

conditional_options=

device_paths=$(echo "${alsa_list}" | jq -r "[.cards[] | .by_path, .by_id // empty] | unique[]")
for device in ${device_paths}; do

  mixers=$(echo "${alsa_list}" | jq -r ".cards[] | select(.by_path == \"${device}\" or .by_id == \"${device}\") | .mixer_controls // {} | keys[]")
  if [ -z "${mixers}" ]; then
    validation='^$'
  else
    key_validation=
    for mixer in ${mixers}; do
      key_validation+="|${mixer}"
    done
    validation="^((${key_validation:1})=[0-9]{1,3}%,?)*\$"
  fi

  conditional_options+="{\"preconditions\":[\"DC_DEVICE_PATH=${device}\"],\"validation\":\"${validation}\"}"
done

echo "${conditional_options}" | jq -cs