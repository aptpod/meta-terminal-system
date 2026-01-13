DESCRIPTION = "Fake hardware clock"
SECTION = "admin"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=0636e73ff0215e8d672dc4c32c317bb3"

SRC_URI = " \
    file://fake-hwclock \
    file://fake-hwclock.default \
    file://fake-hwclock.service \
    file://COPYING \
    file://0001-feat-fake-hwclock.service-runs-after-local-file-syst.patch \
    file://0002-feat-fake-hwclock-runs-before-systemd-journald-and-s.patch \
"

inherit systemd

FILES:${PN} += " \
    ${base_sbindir} \
    ${sysconfdir}/default \
    ${systemd_system_unitdir} \
"

S = "${WORKDIR}"

do_install() {
    install -d ${D}${base_sbindir}
    install -m 0755 ${S}/fake-hwclock ${D}${base_sbindir}/fake-hwclock

    install -d ${D}${sysconfdir}/default
    install -m 0644 ${S}/fake-hwclock.default ${D}${sysconfdir}/default/fake-hwclock

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/fake-hwclock.service ${D}${systemd_system_unitdir}
}

SYSTEMD_SERVICE:${PN} = "fake-hwclock.service"
