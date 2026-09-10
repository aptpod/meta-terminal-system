#!/usr/bin/env bash
# Common definitions for Camera conditional_options scripts
# WARNING: This file is shared by multiple scripts. Changes affect all scripts in this directory.

# === TYPE definitions (single source of truth) ===
# Format: TYPE_NAME|DATA_NAME

# Encoded types (H.264/VP9 encoding from JPEG source)
TYPES_ENCODED=(
  "H.264 Frame (from JPEG)|h264"
  "H.264 NAL Unit (from JPEG)|h264_nal_unit"
  "H.264 RTP Packet (from JPEG)|h264_rtp_packet"
  "VP9 RTP Packet (from JPEG)|vp9_rtp_packet"
)

# RAW types (encoding from YUY2 source, VGA only)
TYPES_RAW=(
  "H.264 Frame (from YUY2)|h264"
  "H.264 RTP Packet (from YUY2)|h264_rtp_packet"
)

# Pass-through types (no encoding, IP67 camera only)
TYPES_PASSTHROUGH=(
  "H.264 RTP Packet (Pass-Through)|h264_rtp_packet"
)

# JPEG type (no encoding)
TYPES_JPEG=(
  "JPEG (Pass-Through)|jpeg"
)

# === Helper functions ===

# Extract TYPE name from "TYPE|DATA_NAME" format
get_type() { echo "${1%%|*}"; }

# Extract DATA_NAME from "TYPE|DATA_NAME" format
get_data_name() { echo "${1##*|}"; }

# Generate a conditional_options entry
# Usage: entry TYPE OPTIONS DEFAULT [EXTRA_PRECONDITION ...]
#
# Example:
#   entry "H.264 Frame (from JPEG)" '["1", "5", "10"]' "5"
#   -> {"preconditions":["DC_OUTPUT_DATA_TYPE=H.264 Frame (from JPEG)"],"options":["1","5","10"],"default":"5"}
#
#   entry "H.264 Frame (from JPEG)" '["1", "5", "10"]' "5" "DC_WIDTH=1920"
#   -> {"preconditions":["DC_OUTPUT_DATA_TYPE=H.264 Frame (from JPEG)","DC_WIDTH=1920"],"options":["1","5","10"],"default":"5"}
entry() {
  local type="$1"
  local options="$2"
  local default="$3"
  shift 3

  local preconditions="\"DC_OUTPUT_DATA_TYPE=$type\""
  for extra in "$@"; do
    preconditions="$preconditions,\"$extra\""
  done

  echo "{\"preconditions\":[$preconditions],\"options\":$options,\"default\":\"$default\"}"
}

# Generate a disabled entry (options: ["---"], default: "---")
# Usage: entry_disabled TYPE
#
# Example:
#   entry_disabled "JPEG (Pass-Through)"
#   -> {"preconditions":["DC_OUTPUT_DATA_TYPE=JPEG (Pass-Through)"],"options":["---"],"default":"---"}
entry_disabled() {
  local type="$1"
  echo "{\"preconditions\":[\"DC_OUTPUT_DATA_TYPE=$type\"],\"options\":[\"---\"],\"default\":\"---\"}"
}
