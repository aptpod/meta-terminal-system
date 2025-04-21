#!/usr/bin/env bash
set -e

# Since kernel 4.16, changes were made to the UVC driver, and a device node for metadata was added.
# Even with a single camera, two device paths are now generated (e.g., /dev/video0 and /dev/video1).
# Because video data cannot be obtained from the second metadata device file, we check the device caps
# and extract only the device paths from which video data can be obtained.

# V4L2 Capability Flags
# Devices supporting the video capture interface set the V4L2_CAP_VIDEO_CAPTURE or V4L2_CAP_VIDEO_CAPTURE_MPLANE flag
# in the capabilities field of struct v4l2_capability returned by the ioctl VIDIOC_QUERYCAP ioctl.
# https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/dev-capture.html#querying-capabilities
# https://www.kernel.org/doc/html/latest/userspace-api/media/v4l/vidioc-querycap.html
V4L2_CAP_VIDEO_CAPTURE=0x00000001
V4L2_CAP_VIDEO_CAPTURE_MPLANE=0x00001000

DEVICE_PATHS="$@"

options=$(echo "[]" | jq -c)

for dev in $DEVICE_PATHS; do
    if [ -e "$dev" ]; then
        caps_line=$(v4l2-ctl --info -d "$dev" 2>/dev/null | grep "Device Caps")
        if [ -n "$caps_line" ]; then
            caps_hex=$(echo "$caps_line" | sed -n 's/.*0x\([0-9a-fA-F]\+\).*/\1/p')
            caps_decimal=$((16#$caps_hex))
            if (((caps_decimal & $V4L2_CAP_VIDEO_CAPTURE) != 0)) || (((caps_decimal & $V4L2_CAP_VIDEO_CAPTURE_MPLANE) != 0)); then
                options=$(echo "$options" | jq -c ". + [\"$dev\"]")
            fi
        fi
    fi
done

echo "$options"
