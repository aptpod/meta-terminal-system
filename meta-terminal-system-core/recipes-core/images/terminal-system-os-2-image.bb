LICENSE = "MIT"
inherit core-image overlayfs-etc-ts2

IMAGE_BASENAME = "${DISTRO}-image"
IMAGE_LINGUAS = " "
IMAGE_FEATURES += " package-management ssh-server-openssh read-only-rootfs overlayfs-etc"
TERMINAL_IMAGE_EXTRA_INSTALL ?= ""

require conf/distro/include/terminal-system-packagelists.inc
IMAGE_INSTALL:append = " \
    ${TERMINAL_SYSTEM_BASE} \
    ${TERMINAL_SYSTEM_CORE} \
    ${TERMINAL_SYSTEM_NETWORK} \
    ${TERMINAL_SYSTEM_CONNECTOR} \
    ${TERMINAL_SYSTEM_DOCKER} \
    ${TERMINAL_SYSTEM_AWS} \
    ${TERMINAL_SYSTEM_MENDER} \
    ${TERMINAL_IMAGE_EXTRA_INSTALL} \
"

TOOLCHAIN_HOST_TASK:append = " nativesdk-cmake"
TOOLCHAIN_TARGET_TASK:append = " openssl-dev libnl-dev kernel-devsrc c-ares-dev util-linux-dev libgcc-dev libstdc++-dev libstdc++-staticdev"

# overlayfs-etc settings
# Mount /etc before systemd starts using preinit script
# This ensures /etc/systemd/system/ configurations are recognized at boot
OVERLAYFS_ETC_DEVICE = "${MENDER_DATA_PART}"
OVERLAYFS_ETC_FSTYPE = "${@d.getVar('MENDER_DATA_PART_FSTYPE_TO_GEN') if d.getVar('MENDER_DATA_PART_FSTYPE') == 'auto' else d.getVar('MENDER_DATA_PART_FSTYPE')}"
OVERLAYFS_ETC_MOUNT_POINT = "/data"
OVERLAYFS_ETC_MOUNT_OPTIONS = "defaults"
OVERLAYFS_ETC_USE_ORIG_INIT_NAME = "1"
OVERLAYFS_ETC_CREATE_MOUNT_DIRS = "0"
# Use custom preinit template to maintain existing directory structure (/data/overlay/etc)
OVERLAYFS_ETC_INIT_TEMPLATE = "${THISDIR}/files/overlayfs-etc-preinit-ts2.sh.in"
# Create required directories for overlayfs-etc preinit script
ROOTFS_POSTPROCESS_COMMAND += "create_overlayfs_dirs; "
create_overlayfs_dirs() {
    install -d ${IMAGE_ROOTFS}/proc
    install -d ${IMAGE_ROOTFS}/sys
    install -d ${IMAGE_ROOTFS}/run
    install -d ${IMAGE_ROOTFS}/var/run
    install -d ${IMAGE_ROOTFS}/data
}
