DESCRIPTION = "Terminal System 2 provisioning settings"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = " \
    file://ts2-provisioning-config-commit.sh \
    file://ts2-provisioning-config-commit.service \
    file://ts2-config.txt \
"

RDEPENDS:${PN} += " \
    bash \
    jq \
"

FILES:${PN} = " \
    ${bindir} \
    ${systemd_system_unitdir}/ts2-provisioning-config-commit.service \
"

TS2_PROVISIONING_CONFIG_DIR ??= "${TS2_PROVISIONING_CONFIG_DIR_DEFAULT}"
TS2_PROVISIONING_CONFIG_DIR_DEFAULT = "/data"
TS2_PROVISIONING_CONFIG_DEPLOY_DIR_NAME ??= "${TS2_PROVISIONING_CONFIG_DEPLOY_DIR_NAME_DEFAULT}"
TS2_PROVISIONING_CONFIG_DEPLOY_DIR_NAME_DEFAULT = "ts2-provisioning-config-commit"
TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_REQUIRED ??= "1"
TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_DEFAULT ??= ""
TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_DEFAULT_DESCRIPTION ??= ""
TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_VARIABLE_NAME = "${@bb.utils.contains('TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_REQUIRED', '1', 'SERIAL_NUMBER', 'OPT_SERIAL_NUMBER', d)}"

inherit systemd

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/ts2-provisioning-config-commit.sh ${D}${bindir}
    sed -i \
        -e 's:@TS2_PROVISIONING_CONFIG_DIR@:${TS2_PROVISIONING_CONFIG_DIR}:' \
        -e 's:@SERIAL_NUMBER@:${TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_VARIABLE_NAME}:' \
        -e 's:@SERIAL_NUMBER_DEFAULT@:${TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_DEFAULT}:' \
        -e 's:@SERIAL_NUMBER_REQUIRED@:${TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_REQUIRED}:' \
        ${D}${bindir}/ts2-provisioning-config-commit.sh

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/ts2-provisioning-config-commit.service ${D}${systemd_system_unitdir}
}

SYSTEMD_SERVICE:${PN} = " ts2-provisioning-config-commit.service "

inherit deploy

do_deploy() {
    install -d ${DEPLOYDIR}/${TS2_PROVISIONING_CONFIG_DEPLOY_DIR_NAME}
    install -m 0644 ${WORKDIR}/ts2-config.txt ${DEPLOYDIR}/${TS2_PROVISIONING_CONFIG_DEPLOY_DIR_NAME}

    if [ "${TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_REQUIRED}" = "1" ]; then
        local serial_number="${TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_VARIABLE_NAME}"
    else
        local serial_number="#${TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_VARIABLE_NAME}"
    fi

    sed -i \
        -e "s:@SERIAL_NUMBER@:${serial_number}:" \
        -e "s:@SERIAL_NUMBER_DEFAULT_DESCRIPTION@:${TS2_PROVISIONING_CONFIG_SERIAL_NUMBER_DEFAULT_DESCRIPTION}:" \
        ${DEPLOYDIR}/${TS2_PROVISIONING_CONFIG_DEPLOY_DIR_NAME}/ts2-config.txt
}

addtask deploy before do_build after do_install
do_deploy[dirs] += "${DEPLOYDIR}/${TS2_PROVISIONING_CONFIG_DEPLOY_DIR_NAME}"

PACKAGE_ARCH = "${MACHINE_ARCH}"
