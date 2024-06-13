#!/bin/sh -e

OPT=
DEV=/dev/$1
FSYS=

if [[ "$#" -ne 2 ]]; then
    echo "Usage: usb-automount <device name> <mount location>"
    exit
fi

FSYS="$(blkid -o value -s TYPE $DEV)"
if [[ -z "$FSYS" ]]; then
    exit
fi

if [[ $FSYS == "vfat" ]]; then
    OPT+=nosuid,noexec,nodev,flush,gid=100,dmask=000,fmask=111
elif [[ $FSYS == "ntfs" ]]; then
    OPT+=defaults,nosuid,noexec,nodev,gid=100,dmask=000,fmask=111
else
    OPT+=nosuid,noexec,nodev,sync
fi
echo "Mounting $FSYS on $DEV to $2..."
mkdir -p $2
/bin/mount -o $OPT $DEV $2
