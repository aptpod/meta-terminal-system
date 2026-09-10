SUMMARY = "Recipe for Terminal System Cored"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit goarch mender-state-scripts

SRC_URI = "file://${TS_RESOURCES_DIR}/cored.${TS_CORED_VERSION}.linux-${TARGET_GOARCH} \
           file://default/docker-compose/measurement/docker-compose.override.yml \
           file://default/docker-compose/measurement/device_connector/device-inventory.fragment.json \
           file://default/intdash/agent.yaml \
           file://default/gps.json \
           file://default/time_sync.json \
           file://diagnostic-monitors/agent_data_point_dropping.yml \
           file://diagnostic-monitors/agent_quitting.yml \
           file://diagnostic-monitors/apt_usbtrx_fw_rx_dropped.yml \
           file://diagnostic-monitors/apt_usbtrx_ringbuffer_is_full.yml \
           file://diagnostic-monitors/diskusage_data.yml \
           file://diagnostic-monitors/docker_container_error.yml \
           file://diagnostic-monitors/high_cpu_usage.yml \
           file://diagnostic-monitors/intdash_server_license_limit_measurement_rejected.yml \
           file://diagnostic-monitors/intdash_server_license_limit_realtime_nacked.yml \
           file://diagnostic-monitors/intdash_server_license_limit_upload_blocked.yml \
           file://diagnostic-monitors/intdash_server_request_timeout.yml \
           file://diagnostic-monitors/rtc_battery_empty.yml \
           file://diagnostic-monitors/unexpected_power_interruption.yml \
           file://docker-compose/system/docker-compose.yml \
           file://docker-compose/system/launch.yml \
           file://docker-compose/measurement/docker-compose.yml \
           file://docker-compose/measurement/services/ANALOG-USB_Interface.yml \
           file://docker-compose/measurement/services/Audio.yml \
           file://docker-compose/measurement/services/Audio/audio_bitrate.sh \
           file://docker-compose/measurement/services/Audio/audio_bitrate_type.sh \
           file://docker-compose/measurement/services/Audio/audio_format.sh \
           file://docker-compose/measurement/services/Audio/audio_jack_element.sh \
           file://docker-compose/measurement/services/Audio/audio_jack_iface.sh \
           file://docker-compose/measurement/services/Audio/audio_rate.sh \
           file://docker-compose/measurement/services/Audio/data_name.sh \
           file://docker-compose/measurement/services/Audio/device_path.sh \
           file://docker-compose/measurement/services/Audio/mixer_args.sh \
           file://docker-compose/measurement/services/Camera/bitrate_bps.sh \
           file://docker-compose/measurement/services/Camera/bitrate_kbps.sh \
           file://docker-compose/measurement/services/Camera/data_name.sh \
           file://docker-compose/measurement/services/Camera/camera_common.sh \
           file://docker-compose/measurement/services/Camera/fps_edgeplant_usb_camera.sh \
           file://docker-compose/measurement/services/Camera/fps_edgeplant_usb_3.0_camera_ip67.sh \
           file://docker-compose/measurement/services/Camera/height_edgeplant_usb_camera.sh \
           file://docker-compose/measurement/services/Camera/videoflip.sh \
           file://docker-compose/measurement/services/Camera/width_edgeplant_usb_camera.sh \
           file://docker-compose/measurement/services/CAN-USB_Interface_(Downstream).yml \
           file://docker-compose/measurement/services/CAN-USB_Interface_(Upstream).yml \
           file://docker-compose/measurement/services/CAN-USB_Interface.yml \
           file://docker-compose/measurement/services/CAN_FD_USB_Interface_(Downstream).yml \
           file://docker-compose/measurement/services/CAN_FD_USB_Interface_(Upstream).yml \
           file://docker-compose/measurement/services/CAN_FD_USB_Interface.yml \
           file://docker-compose/measurement/services/Device_Inventory.yml \
           file://docker-compose/measurement/services/Gamepad/device_path.sh \
           file://docker-compose/measurement/services/Gamepad_(Upstream).yml \
           file://docker-compose/measurement/services/GPS_(NMEA).yml \
           file://docker-compose/measurement/services/GPS_(UBX).yml \
           file://docker-compose/measurement/services/GPS/device_path.sh \
           file://docker-compose/measurement/services/GPS_(NMEA)_(System-Configured).yml \
           file://docker-compose/measurement/services/GPS_(UBX)_(System-Configured).yml \
           file://docker-compose/measurement/services/SocketCAN.yml \
           file://docker-compose/measurement/services/SocketCAN_(Upstream).yml \
           file://docker-compose/measurement/services/SocketCAN_(Downstream).yml \
           file://docker-compose/measurement/services/SocketCAN/interface.sh \
           file://band-preset.yml \
           file://band-preset/em7430.yml \
           file://band-preset/em7431.yml \
           file://band-preset/em05gfa.yml \
           file://band-preset/rm520n-gl.yml \
           file://terminal-system-cored.service \
           ${TS_SRC_URI_MENDER_OPERATION_ARTIFACTS} \
          "

SRC_URI:append:mender-image = " \
    file://state-scripts/SetCommitDeviceConnectorsToTrue \
    file://state-scripts/SetTimeSyncDefault \
    file://state-scripts/MigrateHomeOverlay \
    file://state-scripts/MigrateProxyConfigToOverlayfs \
    file://state-scripts/BackupDeviceConnectorFragments \
    file://state-scripts/RestoreDeviceConnectorFragments \
    file://state-scripts/CleanupDeviceConnectorFragmentsBackup \
    file://state-scripts/MigrateCameraServices \
    file://state-scripts/MigrateStreamerLogFile \
    file://state-scripts/MigrateDhcpcdState \
"

PV = "${TS_CORED_VERSION}"
PR = "r0"

S = "${WORKDIR}/${TS_RESOURCES_DIR}"

inherit systemd

FILES:${PN} = "/usr/bin/cored \
               ${sysconfdir}/core \
               ${systemd_system_unitdir}/terminal-system-cored.service \
               ${datadir}/mender-artifacts \
              "
INHIBIT_PACKAGE_STRIP = "1"
INHIBIT_PACKAGE_DEBUG_SPLIT = "1"

CONFFILES:${PN} += ""

RDEPENDS:${PN} += " \
    device-connector-intdash \
    device-connector-plugins-gps \
    device-connector-plugins-intdash \
    device-connector-plugins-zabbix-inventory  \
    device-connector-utils \
    v4l-utils \
"
# The cored binary is pre-built using an external build system.
# On x86-64, there are path differences between Yocto and the build environment.
# Adding lsb-ld resolves these differences by linking /lib64 to /lib.
RDEPENDS:${PN} += " lsb-ld"

do_compile() {
    :
}
do_compile:append:mender-image() {
    # ArtifactInstall_Leave
    cp ${WORKDIR}/state-scripts/BackupDeviceConnectorFragments ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_20_BackupDeviceConnectorFragments
    cp ${WORKDIR}/state-scripts/SetCommitDeviceConnectorsToTrue ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_SetCommitDeviceConnectorsToTrue
    cp ${WORKDIR}/state-scripts/SetTimeSyncDefault ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_SetTimeSyncDefault
    cp ${WORKDIR}/state-scripts/MigrateHomeOverlay ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateHomeOverlay
    cp ${WORKDIR}/state-scripts/MigrateProxyConfigToOverlayfs ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateProxyConfigToOverlayfs
    cp ${WORKDIR}/state-scripts/MigrateCameraServices ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateCameraServices
    cp ${WORKDIR}/state-scripts/MigrateStreamerLogFile ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateStreamerLogFile
    cp ${WORKDIR}/state-scripts/MigrateDhcpcdState ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateDhcpcdState
    # ArtifactRollback_Enter
    cp ${WORKDIR}/state-scripts/RestoreDeviceConnectorFragments ${MENDER_STATE_SCRIPTS_DIR}/ArtifactRollback_Enter_20_RestoreDeviceConnectorFragments
    # ArtifactCommit_Enter
    cp ${WORKDIR}/state-scripts/CleanupDeviceConnectorFragmentsBackup ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Enter_20_CleanupDeviceConnectorFragmentsBackup
}

do_install[network] = "1"
do_install() {
    bbplain "version: ${TS_CORED_VERSION}, arch: ${TARGET_GOARCH}, md5: $(md5sum ${S}/cored.${TS_CORED_VERSION}.linux-${TARGET_GOARCH})"

    install -d ${D}/usr/bin
    install -m 0755 ${S}/cored.${TS_CORED_VERSION}.linux-${TARGET_GOARCH} ${D}/usr/bin/cored

    # Setup /etc/systemd

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/terminal-system-cored.service ${D}${systemd_system_unitdir}
    sed -i \
        -e 's:@TS_INTDASH_UID@:${TS_INTDASH_UID}:g' \
        -e 's:@TS_INTDASH_GID@:${TS_INTDASH_GID}:g' \
        ${D}${systemd_system_unitdir}/terminal-system-cored.service

    # Setup /etc/core files

    install -d ${D}${sysconfdir}/core
    install -m 0644 ${WORKDIR}/band-preset.yml ${D}${sysconfdir}/core/band-preset.yml

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
    # Merge common and machine-specific agent configurations
    if [ -f ${WORKDIR}/default/intdash/agent.yaml.append ]; then
        yq eval-all 'select(fileIndex == 0) * select(fileIndex == 1)' \
            ${WORKDIR}/default/intdash/agent.yaml \
            ${WORKDIR}/default/intdash/agent.yaml.append \
            > ${WORKDIR}/default/intdash/agent.yaml.tmp
        mv ${WORKDIR}/default/intdash/agent.yaml.tmp ${WORKDIR}/default/intdash/agent.yaml
    fi
    # agent.yaml holds the intdash client secret. It is owned by the intdash user in the
    # intdash-edge-agent2 container, which reads and writes it over the bind mount.
    install -m 0600 -o ${TS_INTDASH_UID} -g ${TS_INTDASH_GID} ${WORKDIR}/default/intdash/agent.yaml ${D}${sysconfdir}/core/default/intdash/agent.yaml
    install -m 0644 ${WORKDIR}/default/gps.json ${D}${sysconfdir}/core/default/gps.json
    install -m 0644 ${WORKDIR}/default/time_sync.json ${D}${sysconfdir}/core/default/time_sync.json

    if [ "${DEFAULT_GPS_MESSAGE_TYPE}" = "ubx" ]; then
        DEFAULT_GPS_BAUDRATE="${DEFAULT_GPS_UBX_BAUDRATE}"
    else
        DEFAULT_GPS_BAUDRATE="${DEFAULT_GPS_NMEA_BAUDRATE}"
    fi

    sed -i \
        -e "s:@DEFAULT_GPS_DEVICE_PATH@:${DEFAULT_GPS_DEVICE_PATH}:" \
        -e "s:@DEFAULT_GPS_BAUDRATE@:${DEFAULT_GPS_BAUDRATE}:" \
        -e "s:@DEFAULT_GPS_MESSAGE_TYPE@:${DEFAULT_GPS_MESSAGE_TYPE}:" \
        -e "s:@DEFAULT_PPS_DEVICE_PATH@:${DEFAULT_PPS_DEVICE_PATH}:" \
        ${D}${sysconfdir}/core/default/gps.json
    if [ -n "${DEFAULT_GPS_DEVICE_PATH}" ]; then
        sed -i \
            -e 's/"sync_with_gps_pps":false/"sync_with_gps_pps":true/' \
            ${D}${sysconfdir}/core/default/time_sync.json
    fi

    # Setup /etc/core/diagnostic-monitors

    install -d ${D}${sysconfdir}/core/diagnostic-monitors
    for monitor in $(find ${WORKDIR}/diagnostic-monitors -mindepth 1 -maxdepth 1 -type f); do
        install -m 0644 ${monitor} "${D}${sysconfdir}/core/diagnostic-monitors/$(basename ${monitor})"
    done

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
HTTP_PROXY=\$HTTP_PROXY
HTTPS_PROXY=\$HTTPS_PROXY
NO_PROXY=\$NO_PROXY
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

    sed -i \
        -e 's:@DEFAULT_GPS_DEVICE_PATH@:${DEFAULT_GPS_DEVICE_PATH}:' \
        -e 's:@DEFAULT_GPS_NMEA_BAUDRATE@:${DEFAULT_GPS_NMEA_BAUDRATE}:' \
        ${D}${sysconfdir}/core/docker-compose/measurement/services/GPS\ \(NMEA\).yml
    sed -i \
        -e 's:@DEFAULT_GPS_DEVICE_PATH@:${DEFAULT_GPS_DEVICE_PATH}:' \
        -e 's:@DEFAULT_GPS_UBX_BAUDRATE@:${DEFAULT_GPS_UBX_BAUDRATE}:' \
        ${D}${sysconfdir}/core/docker-compose/measurement/services/GPS\ \(UBX\).yml
    if [ -z "${DEFAULT_GPS_DEVICE_PATH}" ]; then
        rm -f ${D}${sysconfdir}/core/docker-compose/measurement/services/GPS\ \(NMEA\)\ \(System-Configured\).yml
        rm -f ${D}${sysconfdir}/core/docker-compose/measurement/services/GPS\ \(UBX\)\ \(System-Configured\).yml
    fi

    # Setup mender-artifacts
    install -m 755 -d ${D}${datadir}/mender-artifacts
    for src_uri in ${TS_SRC_URI_MENDER_OPERATION_ARTIFACTS}; do
        artifact="$(basename ${src_uri})"
        install -m 0644 ${S}/${artifact} ${D}${datadir}/mender-artifacts/${artifact}
    done
}

SYSTEMD_SERVICE:${PN} = " terminal-system-cored.service "