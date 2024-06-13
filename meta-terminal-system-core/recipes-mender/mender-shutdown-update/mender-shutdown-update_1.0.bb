FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://mender-shutdown-update.service \
           file://mender-device-api-update-controlmap.sh \
           file://mender-shutdown-update.sh \
          "

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd

S = "${WORKDIR}"

RDEPENDS:${PN} += "bash"
FILES:${PN} = "${bindir} ${systemd_system_unitdir}"


do_install() {
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/mender-shutdown-update.service ${D}${systemd_system_unitdir}

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mender-device-api-update-controlmap.sh ${D}${bindir}
    install -m 0755 ${WORKDIR}/mender-shutdown-update.sh ${D}${bindir}
}

SYSTEMD_SERVICE:${PN} = "\
mender-shutdown-update.service \
"
