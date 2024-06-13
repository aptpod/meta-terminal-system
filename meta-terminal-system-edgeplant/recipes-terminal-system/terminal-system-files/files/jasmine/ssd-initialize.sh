#!/bin/bash

SSD_MOUNT_PATH="/media/ssd"
SSD_INITIALIZED_FILE="/data/.ssd_initialized"

function medis_ssd_is_mounted() {
    systemctl is-active --quiet media-ssd.mount
    return $?
}

function initialize_ssd() {
    # Check ssd mount
    part_path="$(df | grep $SSD_MOUNT_PATH | awk '{print $1}')"
    if [ -z "$part_path" ]; then
        echo "SSD is not mounted."
        return
    fi

    dev_name="$(basename $part_path)"
    dev_path=${part_path%?}

    # Initialize SSD
    echo "Initialize SSD ($dev_name)"
    umount -A $SSD_MOUNT_PATH
    sgdisk -Z $dev_path
    echo y | sgdisk --new 0:: -c 1:"Linux filesystem" $dev_path
    partprobe $dev_path
    sleep 1
    umount -A $SSD_MOUNT_PATH
    mkfs -t ext4 -F $part_path

    while ! medis_ssd_is_mounted; do
        systemctl restart ssd-mount@$dev_name.service
        sleep 1
    done

    touch ${SSD_INITIALIZED_FILE}
}

if [ -e "${SSD_INITIALIZED_FILE}" ]; then
    echo "Already initialized."
    exit 1
fi

initialize_ssd
