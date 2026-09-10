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

# Not in fstab, so systemd's boot-time fsck never covers this device. -y
# because preen refuses the corruption classes left by power loss. Fail-open:
# refusing to mount would let docker and cored write into unbound /var/lib.
if grep -q "^$DEV " /proc/self/mounts; then
    echo "$DEV is already mounted, skipping fsck"
elif ! command -v e2fsck >/dev/null 2>&1; then
    echo "e2fsck not found, skipping fsck of $DEV"
else
    FSCK_RC=0
    # e2fsck exits 1 after repairing; with sh -e collect the code via ||
    e2fsck -y "$DEV" || FSCK_RC=$?
    echo "e2fsck $DEV exited with $FSCK_RC"
    if [ "$FSCK_RC" -ge 4 ]; then
        echo "WARNING: $DEV still has errors (rc=$FSCK_RC), mounting anyway"
    fi
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
