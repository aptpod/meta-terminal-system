SUMMARY = "Device Connector Intdash"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = " \
    file://${TS_RESOURCES_DIR}/dc-plugin-base_${TS_DEB_VERSION_DC_CORE}_${DPKG_ARCH}.deb \
    file://${TS_RESOURCES_DIR}/dc-runner_${TS_DEB_VERSION_DC_CORE}_${DPKG_ARCH}.deb \
    file://${TS_RESOURCES_DIR}/libdc-core_${TS_DEB_VERSION_DC_CORE}_${DPKG_ARCH}.deb \
    file://${TS_RESOURCES_DIR}/device-connector-intdash-bin_${TS_DEB_VERSION_DEVICE_CONNECTOR}_${DPKG_ARCH}.deb \
    file://${TS_RESOURCES_DIR}/device-connector-plugins-gps_${TS_DEB_VERSION_DEVICE_CONNECTOR}_${DPKG_ARCH}.deb \
    file://${TS_RESOURCES_DIR}/device-connector-plugins-intdash_${TS_DEB_VERSION_DEVICE_CONNECTOR}_${DPKG_ARCH}.deb \
    file://${TS_RESOURCES_DIR}/device-connector-plugins-zabbix-inventory_${TS_DEB_VERSION_DEVICE_CONNECTOR}_${DPKG_ARCH}.deb \
    file://${TS_RESOURCES_DIR}/device-connector-utils_${TS_DEB_VERSION_DEVICE_CONNECTOR}_${DPKG_ARCH}.deb \
    file://ts2.custom.conf \
    file://ts2.fw.apt_usbtrx.conf \
    file://ts2.fw.terminal_display.conf \
    file://ts2.gps.fix.conf \
    file://zabbix_inventory_apt_usbtrx.sh \
    file://zabbix_inventory_custom.sh \
    file://zabbix_inventory_gps_fix.sh \
    file://zabbix_inventory.yml \
    file://libdc-core.conf \
"
SRC_URI:append:mender-image = " \
    file://state-scripts/RemoveUpperdirLdSoCache \
"

PV = "${TS_DEB_VERSION_DEVICE_CONNECTOR}"

PACKAGES =+ " \
    device-connector-plugins-gps \
    device-connector-plugins-intdash \
    device-connector-plugins-zabbix-inventory \
    device-connector-utils \
    dc-plugin-base \
    dc-runner \
    libdc-core \
"

inherit rust-common

export DC_TARGET_SYS = "${@d.getVar('RUST_TARGET_SYS').replace(d.getVar('TARGET_VENDOR') or '-unknown', '')}"

FILES:${PN} = " \
    ${bindir}/device-connector-intdash \
"
FILES:device-connector-plugins-gps = " \
    ${bindir}/dc-utils-gps \
    ${libdir}/${DC_TARGET_SYS}/dc-plugins/libdc_gps.so \
    ${sysconfdir}/dc_conf/gpsd_nmea.yml \
    ${sysconfdir}/dc_conf/gpsd_ubx.yml \
    ${sysconfdir}/dc_conf/nmea.yml \
    ${sysconfdir}/dc_conf/ubx.yml \
"
FILES:device-connector-plugins-intdash = " \
    ${libdir}/${DC_TARGET_SYS}/dc-plugins/libdc_intdash.so \
    ${sysconfdir}/dc_conf/iscp_rest_downstream.yml \
    ${sysconfdir}/dc_conf/iscp_rest_upstream.yml \
    ${sysconfdir}/dc_conf/repeat_process_json.yml \
    ${sysconfdir}/dc_conf/repeat_process_string.yml \
    ${sysconfdir}/dc_conf/replay.yml \
"
FILES:device-connector-plugins-zabbix-inventory = " \
    ${libdir}/${DC_TARGET_SYS}/dc-plugins/libdc_zabbix_inventory.so \
    ${sysconfdir}/dc_conf/zabbix_inventory.yml \
    ${sysconfdir}/dc_conf/scripts/zabbix_inventory_*.sh \
    ${sysconfdir}/zabbix/zabbix_agent2.d/device_connector_intdash.conf \
    ${sysconfdir}/zabbix/zabbix_agent2.d/device_connector_intdash.d \
"
FILES:device-connector-utils = " \
    ${bindir}/dc-utils \
"
FILES:dc-plugin-base = " \
    ${libdir}/${DC_TARGET_SYS}/dc-plugins/libdc_base.so \
"
FILES:dc-runner = " \
    ${bindir}/dc-runner \
"
FILES:libdc-core = " \
    ${libdir}/${DC_TARGET_SYS}/libdc_core.so \
    ${sysconfdir}/ld.so.conf.d/libdc-core.conf \
"

RDEPENDS:${PN} += " \
    bash \
    dc-plugin-base \
    dc-runner \
    libdc-core \
"
RDEPENDS:device-connector-plugins-gps += " \
    libdc-core \
    libudev \
"
RDEPENDS:device-connector-plugins-intdash += " \
    libdc-core \
"
RDEPENDS:device-connector-plugins-zabbix-inventory += " \
    bash \
    coreutils \
    jq \
    libqmi \
    modemmanager \
    usbutils \
    zabbix-agent2 \
    libdc-core \
"
RDEPENDS:device-connector-utils += " \
    alsa-lib \
    alsa-utils \
"
RDEPENDS:dc-plugin-base += " \
    libdc-core \
"
RDEPENDS:dc-runner += " \
    libdc-core \
"

INSANE_SKIP:${PN} += "already-stripped"

do_configure[noexec] = "1"

inherit mender-state-scripts

do_compile:append:mender-image() {
    cp ${WORKDIR}/state-scripts/RemoveUpperdirLdSoCache ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_RemoveUpperdirLdSoCache
}

do_install () {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/usr/bin/device-connector-intdash ${D}${bindir}
    install -m 0755 ${WORKDIR}/usr/bin/dc-utils ${D}${bindir}
    install -m 0755 ${WORKDIR}/usr/bin/dc-utils-gps ${D}${bindir}
    install -m 0755 ${WORKDIR}/usr/bin/dc-runner ${D}${bindir}

    install -d ${D}${libdir}/${DC_TARGET_SYS}/dc-plugins
    install -m 0644 ${WORKDIR}/usr/lib/${DC_TARGET_SYS}/libdc_core.so ${D}${libdir}/${DC_TARGET_SYS}/libdc_core.so
    install -m 0644 ${WORKDIR}/usr/lib/${DC_TARGET_SYS}/dc-plugins/* ${D}${libdir}/${DC_TARGET_SYS}/dc-plugins/

    install -d ${D}${sysconfdir}/dc_conf/scripts
    install -m 0644 ${WORKDIR}/etc/dc_conf/*.yml ${D}${sysconfdir}/dc_conf/
    install -m 0755 ${WORKDIR}/etc/dc_conf/scripts/*.sh ${D}${sysconfdir}/dc_conf/scripts/
    install -m 0644 ${WORKDIR}/zabbix_inventory.yml ${D}${sysconfdir}/dc_conf/
    install -m 0755 ${WORKDIR}/zabbix_inventory_*.sh ${D}${sysconfdir}/dc_conf/scripts/

    install -d ${D}/${sysconfdir}/ld.so.conf.d/
    install -m 0644 ${WORKDIR}/libdc-core.conf ${D}/${sysconfdir}/ld.so.conf.d
    sed -i -e "s:@DC_TARGET_SYS@:${DC_TARGET_SYS}:" ${D}/${sysconfdir}/ld.so.conf.d/libdc-core.conf

    install -d ${D}${sysconfdir}/zabbix/zabbix_agent2.d/device_connector_intdash.d
    install -m 0644 ${WORKDIR}/etc/zabbix/zabbix_agent2.d/device_connector_intdash.conf ${D}${sysconfdir}/zabbix/zabbix_agent2.d/
    install -m 0644 ${WORKDIR}/etc/zabbix/zabbix_agent2.d/device_connector_intdash.d/* ${D}${sysconfdir}/zabbix/zabbix_agent2.d/device_connector_intdash.d/
    install -m 0644 ${WORKDIR}/ts2.*.conf ${D}${sysconfdir}/zabbix/zabbix_agent2.d/device_connector_intdash.d/
}
