FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
    file://terminal_system_config.py \
    file://test_terminal_system_config.py \
    file://restore_custom_config.py \
    file://test_restore_custom_config.py \
    file://0001-feat-add-support-for-05-restore-custom-config-script.patch \
    file://0001-add-update-scripts.patch \
    file://0002-add-dbus-auth-failed-flag-file.patch \
"
SRC_URI:append:mender-image = " \
    file://state-scripts/CheckMenderConfigureReport \
"

FILES:${PN} += " \
    ${libdir}/mender-configure/terminal-system-config \
    ${libdir}/mender-configure/apply-device-config.d/10-terminal-system-config \
    ${libdir}/mender-configure/update-device-config.d/10-terminal-system-config \
    ${libdir}/mender-configure/restore-custom-config \
    ${libdir}/mender-configure/apply-device-config.d/05-restore-custom-config \
    ${sysconfdir} \
"

RDEPENDS:${PN} += " \
    python3-core \
    python3-requests \
    python3-json \
    python3-threading \
"

inherit python3native
DEPENDS += " \
    python3-requests-native \
"

inherit mender-state-scripts

# Apply config only at deployment time
SYSTEMD_AUTO_ENABLE:${PN} = "disable"

do_compile:append() {
    cd ${WORKDIR}
    python3 -B -m unittest test_terminal_system_config.py || bbfatal "termianl_system_config.py Test failed"
    python3 -B -m unittest test_restore_custom_config.py || bbfatal "restore_custom_config.py Test failed"
}

do_compile:append:mender-image() {
    cp ${WORKDIR}/state-scripts/CheckMenderConfigureReport ${MENDER_STATE_SCRIPTS_DIR}/Sync_Leave_30_CheckMenderConfigureReport
}

do_install:append() {
    # erase demo config
    cat > ${D}/data/mender-configure/device-config.json <<EOF
{
EOF
    # Because of Bitbake parsing we have to jump through this hoop to get the
    # final '}' in.
    echo '}' >> ${D}/data/mender-configure/device-config.json

    install -d ${D}/${libdir}/mender-configure
    install -m 755 ${WORKDIR}/terminal_system_config.py ${D}/${libdir}/mender-configure/terminal-system-config
    install -m 755 ${WORKDIR}/restore_custom_config.py ${D}/${libdir}/mender-configure/restore-custom-config

    # scripts are used for both apply/update, so they are managed with symbolic links
    install -d ${D}/${libdir}/mender-configure/apply-device-config.d
    install -d ${D}/${libdir}/mender-configure/update-device-config.d
    ln -s ../terminal-system-config ${D}/${libdir}/mender-configure/apply-device-config.d/10-terminal-system-config
    ln -s ../terminal-system-config ${D}/${libdir}/mender-configure/update-device-config.d/10-terminal-system-config
    # install only apply
    ln -s ../restore-custom-config ${D}/${libdir}/mender-configure/apply-device-config.d/05-restore-custom-config
}