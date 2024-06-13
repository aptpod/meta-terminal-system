FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://30-terminal-system.conf \
"

FILES:${PN}:append = " \
    ${systemd_unitdir}/journald.conf.d/30-terminal-system.conf \
"

do_install:append() {
    install -d ${D}${systemd_unitdir}/journald.conf.d/
    install -m 0644 ${WORKDIR}/30-terminal-system.conf ${D}${systemd_unitdir}/journald.conf.d/30-terminal-system.conf
}
