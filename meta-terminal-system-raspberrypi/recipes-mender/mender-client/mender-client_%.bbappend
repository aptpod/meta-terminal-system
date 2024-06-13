FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://inventory/mender-inventory-device-inventory-vcgencmd \
"

do_install:append() {
    install -d ${D}/${datadir}/mender/inventory
    install -m 755 ${WORKDIR}/inventory/mender-inventory-device-inventory-vcgencmd ${D}/${datadir}/mender/inventory/mender-inventory-device-inventory-vcgencmd
}
