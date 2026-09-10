DESCRIPTION = "Cellular module runtime initialization framework"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

inherit systemd

SRC_URI = "\
    file://cellular-module-init-dispatch.sh \
    file://cellular-module-init.service \
    file://30-em74xx-gps.rules \
    file://30-rm520n-gps.rules \
    file://30-em05-gps.rules \
    file://em74xx/init.sh \
"

S = "${WORKDIR}"

FILES:${PN} = "\
    ${bindir}/cellular-module-init-dispatch.sh \
    ${systemd_system_unitdir}/cellular-module-init.service \
    ${sysconfdir}/udev/rules.d/30-em74xx-gps.rules \
    ${sysconfdir}/udev/rules.d/30-rm520n-gps.rules \
    ${sysconfdir}/udev/rules.d/30-em05-gps.rules \
    ${sysconfdir}/cellular-module-init \
"

SYSTEMD_SERVICE:${PN} = "cellular-module-init.service"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/cellular-module-init-dispatch.sh ${D}${bindir}/

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/cellular-module-init.service ${D}${systemd_system_unitdir}/

    if [ "${USE_MODEM_GNSS}" = "yes" ]; then
        install -d ${D}${sysconfdir}/udev/rules.d
        install -m 0644 ${WORKDIR}/30-em74xx-gps.rules ${D}${sysconfdir}/udev/rules.d/
        install -m 0644 ${WORKDIR}/30-rm520n-gps.rules ${D}${sysconfdir}/udev/rules.d/
        install -m 0644 ${WORKDIR}/30-em05-gps.rules ${D}${sysconfdir}/udev/rules.d/

        install -d ${D}${sysconfdir}/cellular-module-init/em74xx
        install -m 0755 ${WORKDIR}/em74xx/init.sh ${D}${sysconfdir}/cellular-module-init/em74xx/
    fi
}
