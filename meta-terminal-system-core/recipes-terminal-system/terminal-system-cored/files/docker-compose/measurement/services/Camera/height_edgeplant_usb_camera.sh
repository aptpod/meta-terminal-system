#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

# HD/FHD resolution options
OPTIONS_HD_FHD='["720", "1080"]'
DEFAULT_HD_FHD="720"

# VGA resolution options
OPTIONS_VGA='["480"]'
DEFAULT_VGA="480"

{
  for item in "${TYPES_ENCODED[@]}" "${TYPES_PASSTHROUGH[@]}"; do
    entry "$(get_type "$item")" "$OPTIONS_HD_FHD" "$DEFAULT_HD_FHD"
  done

  for item in "${TYPES_RAW[@]}" "${TYPES_JPEG[@]}"; do
    entry "$(get_type "$item")" "$OPTIONS_VGA" "$DEFAULT_VGA"
  done
} | jq -sc '.'
