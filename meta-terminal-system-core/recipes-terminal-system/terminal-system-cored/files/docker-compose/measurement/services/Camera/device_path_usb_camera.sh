#!/usr/bin/env bash
set -e

DEVICE_PATHS="/dev/video* /dev/v4l/by-id/*"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
"$SCRIPT_DIR/device_path.sh" "${DEVICE_PATHS[@]}"
