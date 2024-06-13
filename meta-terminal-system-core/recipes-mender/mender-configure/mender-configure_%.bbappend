FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://terminal-system-config \
    file://0001-add-update-scripts.patch \
"

FILES:${PN} += " \
    ${libdir}/mender-configure/terminal-system-config \
    ${libdir}/mender-configure/apply-device-config.d/10-terminal-system-config \
    ${libdir}/mender-configure/update-device-config.d/10-terminal-system-config \
"

RDEPENDS:${PN} += " \
    python3-core \
	python3-requests \
	python3-json \
    python3-threading \
"

# Apply config only at deployment time
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_install:append() {
    # erase demo config
    cat > ${D}/data/mender-configure/device-config.json <<EOF
{
EOF
    # Because of Bitbake parsing we have to jump through this hoop to get the
    # final '}' in.
    echo '}' >> ${D}/data/mender-configure/device-config.json

    install -d ${D}/${libdir}/mender-configure
    install -m 755 ${WORKDIR}/terminal-system-config ${D}/${libdir}/mender-configure/terminal-system-config

    # scripts are used for both apply/update, so they are managed with symbolic links
    install -d ${D}/${libdir}/mender-configure/apply-device-config.d
    install -d ${D}/${libdir}/mender-configure/update-device-config.d
    ln -s ../terminal-system-config ${D}/${libdir}/mender-configure/apply-device-config.d/10-terminal-system-config
    ln -s ../terminal-system-config ${D}/${libdir}/mender-configure/update-device-config.d/10-terminal-system-config
}