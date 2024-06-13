FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://identity/mender-device-identity \
    file://inventory/mender-inventory-provides-provision \
    file://inventory/mender-inventory-terminal-system-core \
    file://inventory/mender-inventory-device-inventory \
"

RDEPENDS:${PN} += " \
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
    install -m 755 ${WORKDIR}/inventory/mender-inventory-provides-provision ${D}/${datadir}/mender/inventory/mender-inventory-provides-provision
    install -m 755 ${WORKDIR}/inventory/mender-inventory-terminal-system-core ${D}/${datadir}/mender/inventory/mender-inventory-terminal-system-core
    install -m 755 ${WORKDIR}/inventory/mender-inventory-device-inventory ${D}/${datadir}/mender/inventory/mender-inventory-device-inventory

    # Uninstall unused default inventory scripts
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-bootloader-integration
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-hostinfo
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-network
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-os
    rm -f ${D}/${datadir}/mender/inventory/mender-inventory-rootfs-type
}
