#!/bin/sh
# Sierra Wireless EM-MC74x1 family NMEA stream kick.
# qcserial driver does not auto-open the NMEA stream; firmware needs
# the literal "$GPS_START" string written to /dev/ttyGPS each boot.

GPS_DEVICE_PATH="/dev/ttyGPS"
RETRY=20

start_nmea() {
    retry=0
    while [ "${retry}" -lt "${RETRY}" ]; do
        echo \$GPS_START > "${GPS_DEVICE_PATH}"
        ret=$(timeout 1 cat "${GPS_DEVICE_PATH}")
        if [ -n "${ret}" ]; then
            return 0
        fi
        retry=$((retry + 1))
    done
    echo "Failed to start GPS" >&2
    return 1
}

if [ -e "${GPS_DEVICE_PATH}" ]; then
    stty -F "${GPS_DEVICE_PATH}" -icrnl 9600
    start_nmea
fi
