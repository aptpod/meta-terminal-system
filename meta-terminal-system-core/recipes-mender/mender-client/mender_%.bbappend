FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://identity/mender-device-identity \
    file://inventory/mender-inventory-device-type \
    file://inventory/mender-inventory-provides-provision \
    file://inventory/mender-inventory-terminal-system-core \
    file://inventory/mender-inventory-device-inventory \
    file://cpu-weight.conf \
    file://0001-feat-Allow-forced-commit-without-reboot-during-stand.patch \
    file://0001-feat-accept-comma-separated-no_proxy.patch \
    file://0003-fix-Add-connect-handshake-read-header-timeouts-to-pr.patch \
"

# Patch mender-resize-data-part.sh to use sfdisk instead of parted.
# With overlayfs-etc enabled, /data is already mounted before mender-grow-data.service runs.
# parted fails on mounted partitions with "Warning: Partition is being used".
# Note: parted dependency is kept for partprobe command.
SRC_URI:append:mender-growfs-data:mender-systemd = " \
    file://0002-fix-use-sfdisk-instead-of-parted-for-mounted-parti.patch;patchdir=${WORKDIR} \
"

FILES:mender-update += " \
    ${systemd_system_unitdir}/${MENDER_CLIENT}.service.d \
"

RDEPENDS:mender-update += " \
    bash \
    curl \
    jq \
    device-inventory \
"

PACKAGECONFIG:append = " modules"
PACKAGECONFIG:remove = " inventory-network-scripts"

MENDER_INVENTORY_POLL_INTERVAL_SECONDS = "60"
MENDER_RETRY_POLL_INTERVAL_SECONDS = "60"
MENDER_UPDATE_POLL_INTERVAL_SECONDS = "60"

do_install:append() {
    # Override identity script to pre-authenticate with serial number only
    install -d ${D}/${datadir}/mender/identity
    install -m 755 ${WORKDIR}/identity/mender-device-identity ${D}/${datadir}/mender/identity/mender-device-identity

    # Immediately after provisioning, the software version (rootfs-image.version) is empty.
    # If empty, the MENDER_ARTIFACT_NAME variable at build time is reported as the software version.
    sed -i \
        -e 's:@MENDER_ARTIFACT_NAME@:${MENDER_ARTIFACT_NAME}:' \
        ${WORKDIR}/inventory/mender-inventory-provides-provision

    install -d ${D}/${datadir}/mender/inventory
    install -m 755 ${WORKDIR}/inventory/mender-inventory-device-type ${D}/${datadir}/mender/inventory/mender-inventory-device-type
    install -m 755 ${WORKDIR}/inventory/mender-inventory-provides-provision ${D}/${datadir}/mender/inventory/mender-inventory-provides-provision
    install -m 755 ${WORKDIR}/inventory/mender-inventory-terminal-system-core ${D}/${datadir}/mender/inventory/mender-inventory-terminal-system-core
    install -m 755 ${WORKDIR}/inventory/mender-inventory-device-inventory ${D}/${datadir}/mender/inventory/mender-inventory-device-inventory

    # Uninstall unused default inventory scripts
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-bootloader-integration
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-hostinfo
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-network
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-os
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-provides
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-rootfs-type

    # Adjust CPUWeight for mender-client to prevent high CPU usage during peak times.
    install -d ${D}${systemd_system_unitdir}/${MENDER_CLIENT}.service.d
    install -m 0644 ${WORKDIR}/cpu-weight.conf ${D}${systemd_system_unitdir}/${MENDER_CLIENT}.service.d/
}
