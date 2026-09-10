#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

# NOTE: TYPES_RAW is not used because Pass-through is available on this camera

FPS_OPTIONS_1_TO_30='["1", "5", "10", "15", "30"]'

{
  for item in "${TYPES_ENCODED[@]}"; do
    entry "$(get_type "$item")" "$FPS_OPTIONS_1_TO_30" "15"
  done

  # Pass-through (no encoding, fixed FPS by resolution)
  for item in "${TYPES_PASSTHROUGH[@]}"; do
    entry "$(get_type "$item")" '["30"]' "30" "DC_WIDTH=1280"
    entry "$(get_type "$item")" '["27"]' "27" "DC_WIDTH=1920"
  done

  for item in "${TYPES_JPEG[@]}"; do
    entry "$(get_type "$item")" "$FPS_OPTIONS_1_TO_30" "15"
  done
} | jq -sc '.'
