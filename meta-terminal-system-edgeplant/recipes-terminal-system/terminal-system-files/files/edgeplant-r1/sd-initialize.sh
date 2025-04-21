#!/bin/bash

SD_MOUNT_PATH="/media/sd"
SD_DEV_NAME="mmcblk2"
SD_PART_NAME="${SD_DEV_NAME}p1"
SD_DEV_PATH="/dev/${SD_DEV_NAME}"
SD_PART_PATH="/dev/${SD_PART_NAME}"
SD_INITIALIZED_FILE="/data/.sd_initialized"

function media_sd_is_mounted() {
    systemctl is-active --quiet media-sd.mount
    return $?
}

function sd_mount_service_is_active() {
    systemctl is-active --quiet sd-mount@$1.service
    return $?
}

function initialize_sd() {
    # Check sd mount
    for i in {1..10}; do
        if media_sd_is_mounted; then
            break
        fi
        sleep 0.5
        echo "Waiting for media-sd.mount to be active..."
    done

    # Check sd-mount@mmcblk2p1.service is active
    for i in {1..10}; do
        if sd_mount_service_is_active $SD_PART_NAME; then
            # only unmount if it is mounted
            umount -A $SD_MOUNT_PATH
            break
        fi
        sleep 0.5
        echo "Waiting for sd-mount@$SD_PART_NAME.service to be active..."
    done

    # Initialize SD
    echo "Initialize SD ($SD_DEV_PATH)"
    sgdisk -Z $SD_DEV_PATH
    echo y | sgdisk --new 0:: -c 1:"Linux filesystem" $SD_DEV_PATH
    partprobe $SD_DEV_PATH
    sleep 1
    umount -A $SD_MOUNT_PATH
    mkfs -t ext4 -F $SD_PART_PATH

    while ! media_sd_is_mounted; do
        systemctl restart sd-mount@$SD_PART_NAME.service
        sleep 1
    done

    touch ${SD_INITIALIZED_FILE}
    sync
}

if [ -e "${SD_INITIALIZED_FILE}" ]; then
    echo "Already initialized."
    exit 1
fi

initialize_sd
