FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:mender-image = " \
    file://var-lib-bluetooth.mount \
"

FILES:${PN}:append:mender-image = " \
    ${systemd_unitdir}/system \
"

do_install:append:mender-image() {
    install -d -m 755 ${D}${systemd_unitdir}/system/
    install -m 644 ${WORKDIR}/var-lib-bluetooth.mount ${D}${systemd_unitdir}/system/
}
