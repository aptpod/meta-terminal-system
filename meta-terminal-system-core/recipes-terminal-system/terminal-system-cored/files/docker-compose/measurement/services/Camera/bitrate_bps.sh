#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

OPTIONS='["500000", "1000000", "2000000", "3000000", "5000000", "8000000"]'
DEFAULT="2000000"

{
  for item in "${TYPES_ENCODED[@]}" "${TYPES_RAW[@]}"; do
    entry "$(get_type "$item")" "$OPTIONS" "$DEFAULT"
  done

  for item in "${TYPES_PASSTHROUGH[@]}" "${TYPES_JPEG[@]}"; do
    entry_disabled "$(get_type "$item")"
  done
} | jq -sc '.'
