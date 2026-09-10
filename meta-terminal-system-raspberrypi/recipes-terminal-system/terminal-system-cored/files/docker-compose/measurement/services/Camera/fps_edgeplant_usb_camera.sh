#!/usr/bin/env bash
set -e
source "$(dirname "$0")/camera_common.sh"

FPS_OPTIONS_1_TO_30='["1", "5", "10", "15", "30"]'
FPS_OPTIONS_1_TO_20='["1", "5", "10", "15", "20"]'
FPS_OPTIONS_1_TO_15='["1", "5", "10", "15"]'
FPS_OPTIONS_1_TO_5='["1", "5"]'

# Videoflip values that require FPS limitation (rotation/flip)
VIDEOFLIP_ROTATIONS=("180" "90r" "90l" "horiz" "vert")

{
  # Encoded types: FHD limited to 15fps, rotation limited to 5fps
  for item in "${TYPES_ENCODED[@]}"; do
    type="$(get_type "$item")"
    # No rotation
    entry "$type" "$FPS_OPTIONS_1_TO_30" "15" "DC_WIDTH=1280" "DC_VIDEOFLIP=identity"
    entry "$type" "$FPS_OPTIONS_1_TO_15" "15" "DC_WIDTH=1920" "DC_VIDEOFLIP=identity"
    # With rotation (limited to 5fps)
    for flip in "${VIDEOFLIP_ROTATIONS[@]}"; do
      entry "$type" "$FPS_OPTIONS_1_TO_5" "5" "DC_WIDTH=1280" "DC_VIDEOFLIP=$flip"
      entry "$type" "$FPS_OPTIONS_1_TO_5" "5" "DC_WIDTH=1920" "DC_VIDEOFLIP=$flip"
    done
  done

  # RAW types: no rotation limit (VGA only)
  for item in "${TYPES_RAW[@]}"; do
    entry "$(get_type "$item")" "$FPS_OPTIONS_1_TO_20" "20"
  done

  for item in "${TYPES_JPEG[@]}"; do
    entry "$(get_type "$item")" "$FPS_OPTIONS_1_TO_30" "15"
  done
} | jq -sc '.'
