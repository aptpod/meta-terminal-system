#!/bin/sh -e

OPT="defaults,nosuid,noexec,nodev"
DEV=/dev/$1
MOUNT_LOCATION_SSD="/media/ssd"
LIBDIR_CORE="/var/lib/core"
LIBDIR_DOCKER="/var/lib/docker"

if [[ "$#" -ne 1 ]]; then
    echo "Usage: ssd-mount <device name>"
    exit
fi

echo "Mounting $DEV to $MOUNT_LOCATION_SSD..."
/bin/mkdir -p $MOUNT_LOCATION_SSD
/bin/mount -o $OPT $DEV $MOUNT_LOCATION_SSD

echo "Bind mounting ${MOUNT_LOCATION_SSD}${LIBDIR_CORE} to $LIBDIR_CORE ..."
/bin/mkdir -p $LIBDIR_CORE
/bin/mkdir -p ${MOUNT_LOCATION_SSD}${LIBDIR_CORE}
/bin/mount --bind ${MOUNT_LOCATION_SSD}${LIBDIR_CORE} $LIBDIR_CORE

echo "Bind mounting ${MOUNT_LOCATION_SSD}${LIBDIR_DOCKER} to $LIBDIR_DOCKER ..."
/bin/mkdir -p $LIBDIR_DOCKER
/bin/mkdir -p ${MOUNT_LOCATION_SSD}${LIBDIR_DOCKER}
/bin/mount --bind ${MOUNT_LOCATION_SSD}${LIBDIR_DOCKER} $LIBDIR_DOCKER
