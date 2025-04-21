FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://chrony.conf \
"

do_install:append () {
    install -m 644 ${WORKDIR}/chrony.conf ${D}${sysconfdir}/chrony.conf
    install -d -m 755 ${D}${sysconfdir}/chrony/conf.d
    sed -i \
        -e "/ExecStart=/i ExecStartPre=/bin/sh -c '/usr/bin/cored generate chrony-dropin >${sysconfdir}/chrony/conf.d/terminal-system-core.conf'" \
        -e "/ProtectSystem=/a ReadWritePaths=${sysconfdir}/chrony/conf.d" \
        ${D}${systemd_unitdir}/system/chronyd.service
}