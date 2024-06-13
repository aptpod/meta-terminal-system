#!/usr/bin/env bash
set -e

alsa_list=$(dc-utils alsa list | jq -c)

IFS=$'\n'

conditional_options=

device_paths=$(echo "${alsa_list}" | jq -r ".cards[].by_path")
for device in ${device_paths}; do

  audio_elements=$(echo "${alsa_list}" | jq -r ".cards[] | select(.by_path == \"${device}\") | .jack_elements // {} | keys[]")
  for audio_element in ${audio_elements}; do
    conditional_options+=$(echo "${alsa_list}" | jq -c "{preconditions:[\"DC_DEVICE_PATH=${device}\",\"DC_AUDIO_JACK_ELEMENT=${audio_element}\"], validation:(\"^\"+(.cards[] | select(.by_path == \"${device}\") | .jack_elements // {} | .\"${audio_element}\".interface)+\"\$\")}")
  done

  conditional_options+="{\"preconditions\":[\"DC_DEVICE_PATH=${device}\",\"DC_AUDIO_JACK_ELEMENT=\"],\"validation\":\".*\"}"
done

echo "${conditional_options}" | jq -cs