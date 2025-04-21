SUMMARY = "Device inventory"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = " \
    file://device-inventory \
    file://device-inventory.service \
"

RDEPENDS:${PN} += " \
    bash \
    jq \
    coreutils \
    device-connector-intdash \
    device-connector-plugins-intdash \
    device-connector-plugins-zabbix-inventory \
"

FILES:${PN} = " \
    ${bindir} \
    ${systemd_system_unitdir}/device-inventory.service \
"

inherit systemd

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/device-inventory ${D}${bindir}/device-inventory

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/device-inventory.service ${D}${systemd_system_unitdir}
}

SYSTEMD_SERVICE:${PN} = " device-inventory.service "