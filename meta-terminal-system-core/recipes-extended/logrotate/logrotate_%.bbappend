FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://core.conf \
            file://rsyslog.conf \
"

LOGROTATE_SYSTEMD_TIMER_BASIS = "hourly"
LOGROTATE_SYSTEMD_TIMER_ACCURACY = "30m"

FILES:${PN} += "${sysconfdir}/logrotate.d"

do_install:append() {
        mkdir -p ${D}/${sysconfdir}/logrotate.d
        install -m 644  ${WORKDIR}/core.conf ${D}/${sysconfdir}/logrotate.d
        install -m 644  ${WORKDIR}/rsyslog.conf ${D}/${sysconfdir}/logrotate.d
}