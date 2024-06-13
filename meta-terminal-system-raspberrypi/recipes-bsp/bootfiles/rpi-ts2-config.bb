DESCRIPTION = "Terminal System 2 provisioning settings for raspberry pi"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

COMPATIBLE_MACHINE = "^rpi$"

SRC_URI = " \
    file://ts2-config-commit.sh \
    file://ts2-config-commit.service \
    file://ts2-config.txt \
"

RDEPENDS:${PN} += " \
    bash \
"

FILES:${PN} = " \
    ${bindir} \
    ${systemd_system_unitdir}/ts2-config-commit.service \
"

inherit systemd

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/ts2-config-commit.sh ${D}${bindir}
    sed -i \
        -e 's:@MENDER_BOOT_PART_MOUNT_LOCATION@:${MENDER_BOOT_PART_MOUNT_LOCATION}:' \
        ${D}${bindir}/ts2-config-commit.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ts2-config-commit.service ${D}${systemd_system_unitdir}
}

SYSTEMD_SERVICE:${PN} = " ts2-config-commit.service "

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}
    install -m 0755 ${WORKDIR}/ts2-config.txt ${DEPLOYDIR}/${BOOTFILES_DIR_NAME}/ts2-config.txt
}

addtask deploy before do_build after do_install
do_deploy[dirs] += "${DEPLOYDIR}/${BOOTFILES_DIR_NAME}"

PACKAGE_ARCH = "${MACHINE_ARCH}"
