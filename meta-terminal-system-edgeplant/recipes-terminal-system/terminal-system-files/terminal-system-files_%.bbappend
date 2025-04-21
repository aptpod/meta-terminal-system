FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:edgeplant-r1 = " \
    file://69-persistent-storage-internal.rules \
    file://sd-mount.sh \
    file://sd-mount@.service \
    file://sd-initialize.sh \
    file://sd-initialize.service \
"

inherit mender-state-scripts

do_install:append:edgeplant-r1() {
    install -d ${D}${sysconfdir}/udev/rules.d
    install -m 0644 ${WORKDIR}/69-persistent-storage-internal.rules ${D}${sysconfdir}/udev/rules.d

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/sd-mount.sh ${D}${bindir}/sd-mount.sh
    install -m 0755 ${WORKDIR}/sd-initialize.sh ${D}${bindir}/sd-initialize.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/sd-mount@.service ${D}${systemd_system_unitdir}/sd-mount@.service
    install -m 0644 ${WORKDIR}/sd-initialize.service ${D}${systemd_system_unitdir}/sd-initialize.service
}

RDEPENDS:${PN} += " \
    gptfdisk \
    e2fsprogs \
"

SYSTEMD_SERVICE:${PN}:append:edgeplant-r1 = " \
sd-mount@.service \
sd-initialize.service \
"
