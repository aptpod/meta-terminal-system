require initramfs-module-install-ts2-config.inc

do_install:append:mender-efi-boot() {
    sed -i \
        -e 's#[@]MENDER_BOOT_PART_NUMBER[@]#${MENDER_BOOT_PART_NUMBER}#' \
        -e 's#[@]MENDER_ROOTFS_PART_A_NUMBER[@]#${MENDER_ROOTFS_PART_A_NUMBER}#' \
        -e 's#[@]MENDER_ROOTFS_PART_B_NUMBER[@]#${MENDER_ROOTFS_PART_B_NUMBER}#' \
        -e 's#[@]MENDER_DATA_PART_NUMBER[@]#${MENDER_DATA_PART_NUMBER}#' \
        ${D}/init.d/install-efi.sh
}
