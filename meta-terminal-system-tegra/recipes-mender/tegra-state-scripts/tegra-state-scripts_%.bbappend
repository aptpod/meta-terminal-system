FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://bl-record-rollback-slot \
    file://bl-restore-rollback-slot \
    file://bl-clear-rollback-slot \
"

do_compile:append:tegra186() {
    install -m 0755 ${S}/bl-record-rollback-slot ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_79_bl-record-rollback-slot
    install -m 0755 ${S}/bl-restore-rollback-slot ${MENDER_STATE_SCRIPTS_DIR}/ArtifactRollback_Leave_80_bl-restore-rollback-slot
    install -m 0755 ${S}/bl-clear-rollback-slot ${MENDER_STATE_SCRIPTS_DIR}/ArtifactCommit_Leave_80_bl-clear-rollback-slot
    install -m 0755 ${S}/bl-clear-rollback-slot ${MENDER_STATE_SCRIPTS_DIR}/ArtifactFailure_Leave_80_bl-clear-rollback-slot
}
