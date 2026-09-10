#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

FPS_OPTIONS_1_TO_30='["1", "5", "10", "15", "30"]'
FPS_OPTIONS_1_TO_20='["1", "5", "10", "15", "20"]'

{
  for item in "${TYPES_ENCODED[@]}"; do
    entry "$(get_type "$item")" "$FPS_OPTIONS_1_TO_30" "15"
  done

  for item in "${TYPES_RAW[@]}"; do
    entry "$(get_type "$item")" "$FPS_OPTIONS_1_TO_20" "20"
  done

  for item in "${TYPES_JPEG[@]}"; do
    entry "$(get_type "$item")" "$FPS_OPTIONS_1_TO_30" "15"
  done
} | jq -sc '.'
