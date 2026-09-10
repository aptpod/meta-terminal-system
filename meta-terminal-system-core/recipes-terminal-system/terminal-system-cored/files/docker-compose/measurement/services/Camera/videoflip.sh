#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

OPTIONS='["identity", "180", "90r", "90l", "horiz", "vert"]'
DEFAULT="identity"

{
  for item in "${TYPES_ENCODED[@]}" "${TYPES_RAW[@]}"; do
    entry "$(get_type "$item")" "$OPTIONS" "$DEFAULT"
  done

  for item in "${TYPES_PASSTHROUGH[@]}" "${TYPES_JPEG[@]}"; do
    entry_disabled "$(get_type "$item")"
  done
} | jq -sc '.'
