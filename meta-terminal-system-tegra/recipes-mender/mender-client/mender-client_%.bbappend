FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://inventory/mender-inventory-device-inventory-tegrastats \
"

do_install:append() {
    install -d ${D}/${datadir}/mender/inventory
    install -m 755 ${WORKDIR}/inventory/mender-inventory-device-inventory-tegrastats ${D}/${datadir}/mender/inventory/mender-inventory-device-inventory-tegrastats
}
