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

# Only the filesystem types listed here are mounted. Mounting any other type
# would let an inserted device reach kernel filesystem code the product never
# uses (the kernel autoloads the matching fs-<type> module on mount).
case "$FSYS" in
    vfat)
        OPT+=nosuid,noexec,nodev,flush,gid=100,dmask=000,fmask=111
        ;;
    exfat)
        OPT+=nosuid,noexec,nodev,sync,gid=100,dmask=000,fmask=111
        ;;
    ext2|ext3|ext4)
        OPT+=nosuid,noexec,nodev,sync
        ;;
    *)
        echo "Skip mounting $DEV: unsupported filesystem type '$FSYS'"
        exit
        ;;
esac
echo "Mounting $FSYS on $DEV to $2..."
mkdir -p $2
/bin/mount -t $FSYS -o $OPT $DEV $2
