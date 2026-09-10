#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

OPTIONS='["500", "1000", "2000", "3000", "5000", "8000"]'
DEFAULT="2000"

{
  for item in "${TYPES_ENCODED[@]}" "${TYPES_RAW[@]}"; do
    entry "$(get_type "$item")" "$OPTIONS" "$DEFAULT"
  done

  for item in "${TYPES_PASSTHROUGH[@]}" "${TYPES_JPEG[@]}"; do
    entry_disabled "$(get_type "$item")"
  done
} | jq -sc '.'
