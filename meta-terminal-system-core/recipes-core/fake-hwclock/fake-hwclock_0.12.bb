DESCRIPTION = "Fake hardware clock"
SECTION = "admin"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=0636e73ff0215e8d672dc4c32c317bb3"

SRC_URI = " \
    git://git.einval.com/git/fake-hwclock.git;protocol=https;branch=master \
	file://0001-feat-fake-hwclock.service-runs-after-local-file-syst.patch \
    file://0002-feat-fake-hwclock-runs-before-systemd-journald-and-s.patch \
"
SRCREV = "6652b58ba37566f495cb9b52e71d6858842a2265"

inherit systemd

FILES:${PN} += " \
    ${base_sbindir} \
    ${sysconfdir}/default \
    ${systemd_system_unitdir} \
"

S = "${WORKDIR}/git"

do_install() {
    install -d ${D}${base_sbindir}
    install -m 0755 ${S}/fake-hwclock ${D}${base_sbindir}/fake-hwclock

    install -d ${D}${sysconfdir}/default
    install -m 0644 ${S}/etc/default/fake-hwclock ${D}${sysconfdir}/default

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${S}/debian/fake-hwclock.service ${D}${systemd_system_unitdir}
}

SYSTEMD_SERVICE:${PN} = "fake-hwclock.service"
