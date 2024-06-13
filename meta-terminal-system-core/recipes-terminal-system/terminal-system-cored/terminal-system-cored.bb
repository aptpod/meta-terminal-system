SUMMARY = "Recipe for Terminal System Cored"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit goarch mender-state-scripts

SRC_URI = "file://${TS_RESOURCES_DIR}/cored.${TS_CORED_VERSION}.linux-${TARGET_GOARCH} \
           file://default/docker-compose/measurement/docker-compose.override.yml \
           file://default/docker-compose/measurement/device_connector/device-inventory.fragment.json \
           file://default/intdash/agent.yaml \
           file://docker-compose/system/docker-compose.yml \
           file://docker-compose/system/launch.yml \
           file://docker-compose/measurement/docker-compose.yml \
           file://docker-compose/measurement/services/ANALOG-USB_Interface.yml \
           file://docker-compose/measurement/services/Audio.yml \
           file://docker-compose/measurement/services/Audio/audio_jack_element.sh \
           file://docker-compose/measurement/services/Audio/audio_jack_iface.sh \
           file://docker-compose/measurement/services/Audio/device_path.sh \
           file://docker-compose/measurement/services/Audio/mixer_args.sh \
           file://docker-compose/measurement/services/CAN-USB_Interface_(Downstream).yml \
           file://docker-compose/measurement/services/CAN-USB_Interface_(Upstream).yml \
           file://docker-compose/measurement/services/CAN-USB_Interface.yml \
           file://docker-compose/measurement/services/Device_Inventory.yml \
           file://docker-compose/measurement/services/GPS_(NMEA).yml \
           file://docker-compose/measurement/services/GPS_(UBX).yml \
           file://docker-compose/measurement/services/MJPEG_for_EDGEPLANT_USB_Camera_(v4l2-src).yml \
           file://docker-compose/measurement/services/MJPEG_for_EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/SocketCAN.yml \
           file://docker-compose/measurement/services/SocketCAN_(Upstream).yml \
           file://docker-compose/measurement/services/SocketCAN_(Downstream).yml \
           file://docker-compose/measurement/services/SocketCAN/interface.sh \
           file://band-preset.yml \
           file://event.yml \
           file://terminal-system-cored.service \
          "

SRC_URI:append:mender-image = " \
    file://state-scripts/MigrateAPIUsersPasswd \
    file://state-scripts/SetCommitDeviceConnectorsToTrue \
    file://state-scripts/MigrateDCSettingsH264iSCPv2CompatFormat \
"

PV = "${TS_CORED_VERSION}"
PR = "r0"

S = "${WORKDIR}/${TS_RESOURCES_DIR}"

inherit systemd

FILES:${PN} = "/usr/bin/cored \
               ${sysconfdir}/core \
               ${systemd_system_unitdir}/terminal-system-cored.service \
              "
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

CONFFILES:${PN} += ""

RDEPENDS:${PN} += " \
    device-connector-utils \
"

do_compile() {
    :
}
do_compile:append:mender-image() {
    # ArtifactInstall_Enter
    cp ${WORKDIR}/state-scripts/MigrateDCSettingsH264iSCPv2CompatFormat ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Enter_30_MigrateDCSettingsH264iSCPv2CompatFormat

    # ArtifactInstall_Leave
    cp ${WORKDIR}/state-scripts/MigrateAPIUsersPasswd ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateAPIUsersPasswd
    cp ${WORKDIR}/state-scripts/SetCommitDeviceConnectorsToTrue ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_SetCommitDeviceConnectorsToTrue
}

do_install[network] = "1"
do_install() {
    bbplain "version: ${TS_CORED_VERSION}, arch: ${TARGET_GOARCH}, md5: $(md5sum ${S}/cored.${TS_CORED_VERSION}.linux-${TARGET_GOARCH})"

    install -d ${D}/usr/bin
    install -m 0755 ${S}/cored.${TS_CORED_VERSION}.linux-${TARGET_GOARCH} ${D}/usr/bin/cored

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/terminal-system-cored.service ${D}${systemd_system_unitdir}

    # Setup /etc/core files

    install -d ${D}${sysconfdir}/core
    install -m 0644 ${WORKDIR}/band-preset.yml ${D}${sysconfdir}/core/band-preset.yml
    install -m 0644 ${WORKDIR}/event.yml ${D}${sysconfdir}/core/event.yml

    # The password will be set to an invalid value because it will be reset during provisioning.
    # NOTE: generate command: uuidgen | openssl passwd -apr1 -stdin
    local TS_API_USER_PASS_ADMIN_DEFAULT='$apr1$j3fwECum$Ysl4jchLX0dBi/CMT8kX1.'
    local TS_API_USER_PASS_USER_DEFAULT='$apr1$v0MFkAE/$71ZqCGjWQ10mks8WrlpNc0'
    cat << HTPASSWD_FILE > ${D}${sysconfdir}/core/htpasswd
admin:${TS_API_USER_PASS_ADMIN_DEFAULT}
user:${TS_API_USER_PASS_USER_DEFAULT}
HTPASSWD_FILE
    chmod 0600 ${D}${sysconfdir}/core/htpasswd

    # Setup /etc/core/default

    install -d ${D}${sysconfdir}/core/default/docker-compose/measurement
    install -m 0600 ${WORKDIR}/default/docker-compose/measurement/docker-compose.override.yml ${D}${sysconfdir}/core/default/docker-compose/measurement/docker-compose.override.yml
    install -d ${D}${sysconfdir}/core/default/docker-compose/measurement/device_connector
    install -m 0644 ${WORKDIR}/default/docker-compose/measurement/device_connector/device-inventory.fragment.json ${D}${sysconfdir}/core/default/docker-compose/measurement/device_connector/device-inventory.fragment.json
    install -d ${D}${sysconfdir}/core/default/docker-compose/measurement/services
    install -d ${D}${sysconfdir}/core/default/intdash
    install -m 0666 ${WORKDIR}/default/intdash/agent.yaml ${D}${sysconfdir}/core/default/intdash/agent.yaml

    # Setup /etc/core/docker-compose

    install -d ${D}${sysconfdir}/core/docker-compose
    cat << ENV_FILE > ${D}${sysconfdir}/core/docker-compose/.env
BASE_URI=${TS_IMAGE_BASE_URI}
IMAGE_NAME_AGENT2=${TS_IMAGE_NAME_AGENT2}
IMAGE_TAG_AGENT2=${TS_IMAGE_TAG_AGENT2}
IMAGE_NAME_DEVICE_CONNECTOR=${TS_IMAGE_NAME_DEVICE_CONNECTOR}
IMAGE_TAG_DEVICE_CONNECTOR=${TS_IMAGE_TAG_DEVICE_CONNECTOR}
IMAGE_NAME_TERMINAL_DISPLAY_CLIENT=${TS_IMAGE_NAME_TERMINAL_DISPLAY_CLIENT}
IMAGE_TAG_TERMINAL_DISPLAY_CLIENT=${TS_IMAGE_TAG_TERMINAL_DISPLAY_CLIENT}
ENV_FILE

    install -m 0711 -d ${D}${sysconfdir}/core/docker-compose/system
    install -m 0644 ${WORKDIR}/docker-compose/system/docker-compose.yml ${D}${sysconfdir}/core/docker-compose/system/docker-compose.yml
    install -m 0644 ${WORKDIR}/docker-compose/system/launch.yml ${D}${sysconfdir}/core/docker-compose/system/launch.yml

    install -m 0755 -d ${D}${sysconfdir}/core/docker-compose/measurement/services
    install -m 0644 ${WORKDIR}/docker-compose/measurement/docker-compose.yml ${D}${sysconfdir}/core/docker-compose/measurement/docker-compose.yml
    for service in $(find ${WORKDIR}/docker-compose/measurement/services -mindepth 1 -maxdepth 1 -type f); do
        install -m 0644 ${service} "${D}${sysconfdir}/core/docker-compose/measurement/services/$(basename ${service} | tr _ \ )"
    done
    for service_dir in $(find ${WORKDIR}/docker-compose/measurement/services -mindepth 1 -maxdepth 1 -type d); do
        dirname="$(basename ${service_dir})"
        install -m 0755 -d "${D}${sysconfdir}/core/docker-compose/measurement/services/${dirname}"
        for script in $(find ${WORKDIR}/docker-compose/measurement/services/${dirname} -mindepth 1 -maxdepth 1 -type f); do
            install -m 0755 ${script} "${D}${sysconfdir}/core/docker-compose/measurement/services/${dirname}/$(basename ${script})"
        done
    done
}

SYSTEMD_SERVICE:${PN} = " terminal-system-cored.service "