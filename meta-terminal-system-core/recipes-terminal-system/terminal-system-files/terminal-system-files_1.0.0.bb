SUMMARY = "Terminal System files"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd

SRC_URI = " \
    file://20-usb.rules \
    file://99-terminal-display.rules \
    file://terminal-display.conf \
    file://usb-automount.sh \
    file://usb-automount@.service \
"

SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

RDEPENDS:${PN} += "bash"

FILES:${PN} = "${sysconfdir} ${bindir} ${systemd_system_unitdir}"

do_install() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/20-usb.rules ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/99-terminal-display.rules ${D}${sysconfdir}/udev/rules.d

    install -d ${D}${sysconfdir}/terminal-display
    install -m 0644 ${WORKDIR}/terminal-display.conf ${D}${sysconfdir}/terminal-display/terminal-display.conf

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/usb-automount.sh ${D}${bindir}/usb-automount.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/usb-automount@.service ${D}${systemd_system_unitdir}/usb-automount@.service
}

SYSTEMD_SERVICE:${PN} = "\
usb-automount@.service \
"
