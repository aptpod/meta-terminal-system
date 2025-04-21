FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://MigrateRootHome \
"

do_compile:append() {
    cp MigrateRootHome ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_80_MigrateRootHome
}
