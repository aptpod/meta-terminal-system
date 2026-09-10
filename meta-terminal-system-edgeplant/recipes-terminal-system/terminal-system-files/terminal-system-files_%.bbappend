FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:jasmine = " \
    file://69-persistent-storage-internal.rules \
    file://ssd-mount.sh \
    file://ssd-mount@.service \
    file://ssd-initialize.sh \
    file://ssd-initialize.service \
"

do_install:append:jasmine() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/69-persistent-storage-internal.rules ${D}${sysconfdir}/udev/rules.d

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/ssd-mount.sh ${D}${bindir}/ssd-mount.sh
    install -m 0755 ${WORKDIR}/ssd-initialize.sh ${D}${bindir}/ssd-initialize.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ssd-mount@.service ${D}${systemd_system_unitdir}/ssd-mount@.service
    install -m 0644 ${WORKDIR}/ssd-initialize.service ${D}${systemd_system_unitdir}/ssd-initialize.service
}

RDEPENDS:${PN}:append:jasmine = " \
    gptfdisk \
    e2fsprogs \
"

SYSTEMD_SERVICE:${PN}:append:jasmine = " \
ssd-mount@.service \
ssd-initialize.service \
"
