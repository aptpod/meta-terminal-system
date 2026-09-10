#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

{
  for item in "${TYPES_ENCODED[@]}" "${TYPES_RAW[@]}" "${TYPES_PASSTHROUGH[@]}" "${TYPES_JPEG[@]}"; do
    type="$(get_type "$item")"
    name="$(get_data_name "$item")"
    entry "$type" "[\"$name\"]" "$name"
  done
} | jq -sc '.'
