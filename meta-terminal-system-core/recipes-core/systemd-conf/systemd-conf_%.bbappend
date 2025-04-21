FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit mender-state-scripts

SRC_URI:append = " \
    file://30-terminal-system.conf \
    file://state-scripts/CopySystemdConfForTerminalSystemCore \
"

FILES:${PN}:append = " \
    ${systemd_unitdir}/journald.conf.d/30-terminal-system.conf \
"

do_compile:append:mender-image() {
    cp ${WORKDIR}/state-scripts/CopySystemdConfForTerminalSystemCore ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_CopySystemdConfForTerminalSystemCore
}

do_install:append() {
    install -d ${D}${systemd_unitdir}/journald.conf.d/
    install -m 0644 ${WORKDIR}/30-terminal-system.conf ${D}${systemd_unitdir}/journald.conf.d/30-terminal-system.conf
}
