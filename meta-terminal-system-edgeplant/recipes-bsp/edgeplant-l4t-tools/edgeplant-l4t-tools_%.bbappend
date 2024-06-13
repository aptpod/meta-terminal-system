FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# override package
SRC_URI = "file://${TS_RESOURCES_DIR}/edgeplant-l4t-tools_${TS_EDGEPLANT_L4T_TOOLS_VERSION}_arm64.deb"
SRC_URI += "file://0001-feat-exclusive-access-to-powermanage.patch"
PV = "${TS_EDGEPLANT_L4T_TOOLS_VERSION}"

do_install:append () {
    # NOTE: **DO NOT INSTALL** edgeplant-l4t-boot.service
    # Startup process is performed by terminal-system-cored and device-connector-intdash
    rm ${D}${systemd_system_unitdir}/edgeplant-l4t-boot.service
}

SYSTEMD_SERVICE:${PN} = "edgeplant-l4t-faultlog.service edgeplant-l4t-shutdown.service"
