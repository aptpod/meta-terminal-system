#!/bin/bash

SSD_MOUNT_PATH="/media/ssd"
SSD_INITIALIZED_FILE="/data/.ssd_initialized"

function media_ssd_is_mounted() {
    systemctl is-active --quiet media-ssd.mount
    return $?
}

function ssd_mount_service_is_active() {
    systemctl is-active --quiet ssd-mount@$1.service
    return $?
}

function initialize_ssd() {
    # Check ssd mount
    for i in {1..10}; do
        if media_ssd_is_mounted; then
            break
        fi
        sleep 0.5
        echo "Waiting for media-ssd.mount to be active..."
    done

    part_path="$(df | grep $SSD_MOUNT_PATH | awk '{print $1}')"
    if [ -z "$part_path" ]; then
        echo "SSD is not mounted."
        return
    fi

    dev_name="$(basename $part_path)"    # ex) sda1
    dev_path=${part_path%?}              # ex) /dev/sda

    # Check ssd-mount@sd[a-z]1.service is active
    for i in {1..10}; do
        if ssd_mount_service_is_active $dev_name; then
            break
        fi
        sleep 0.5
        echo "Waiting for ssd-mount@$dev_name.service to be active..."
    done

    # Initialize SSD
    echo "Initialize SSD ($dev_name)"
    umount -A $SSD_MOUNT_PATH
    sgdisk -Z $dev_path
    echo y | sgdisk --new 0:: -c 1:"Linux filesystem" $dev_path
    partprobe $dev_path
    sleep 1
    umount -A $SSD_MOUNT_PATH
    mkfs -t ext4 -F $part_path

    while ! media_ssd_is_mounted; do
        systemctl restart ssd-mount@$dev_name.service
        sleep 1
    done

    touch ${SSD_INITIALIZED_FILE}
    sync
}

if [ -e "${SSD_INITIALIZED_FILE}" ]; then
    echo "Already initialized."
    exit 1
fi

initialize_ssd
