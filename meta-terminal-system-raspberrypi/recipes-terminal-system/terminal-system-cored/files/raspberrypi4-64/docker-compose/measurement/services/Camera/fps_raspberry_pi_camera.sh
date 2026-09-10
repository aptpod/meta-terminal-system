#!/usr/bin/env bash
set -e

FPS_OPTIONS='["5", "10", "15", "30"]'
FPS_OPTIONS_ROTATION='["5"]'

# Videoflip values that require FPS limitation (rotation/flip)
VIDEOFLIP_ROTATIONS=("180" "90r" "90l" "horiz" "vert")

{
  # No rotation: full FPS range
  echo "{\"preconditions\":[\"DC_VIDEOFLIP=identity\"],\"options\":$FPS_OPTIONS,\"default\":\"15\"}"

  # With rotation: limited to 5fps
  for flip in "${VIDEOFLIP_ROTATIONS[@]}"; do
    echo "{\"preconditions\":[\"DC_VIDEOFLIP=$flip\"],\"options\":$FPS_OPTIONS_ROTATION,\"default\":\"5\"}"
  done
} | jq -sc '.'
