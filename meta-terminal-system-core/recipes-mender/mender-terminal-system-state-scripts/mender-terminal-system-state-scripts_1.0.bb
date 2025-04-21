FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://UpdateStateFile \
           file://SetInventoryProvidesReportFlag \
          "

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit mender-state-scripts

S = "${WORKDIR}"

copy_update_state_file() {
    # The order is 00 for Enter and 99 for Leave.
    # The Enter state is processed at the beginning of other scripts,
    # and the Leave state is processed at the end of other scripts.
    local state=$1
    sed -i  -e "s:STATE_SCRIPT_STATE=.*:STATE_SCRIPT_STATE=\"${state}_Enter\":" UpdateStateFile
    cp UpdateStateFile ${MENDER_STATE_SCRIPTS_DIR}/${state}_Enter_00_UpdateStateFile
    sed -i  -e "s:STATE_SCRIPT_STATE=.*:STATE_SCRIPT_STATE=\"${state}_Leave\":" UpdateStateFile
    cp UpdateStateFile ${MENDER_STATE_SCRIPTS_DIR}/${state}_Leave_99_UpdateStateFile
}

do_compile() {
    # Add a script to get the state
    # mender-client does not have a way to get the state by default
    # https://hub.mender.io/t/is-there-a-way-for-a-client-device-to-monitor-the-status-and-progress-of-an-update/558/2
    copy_update_state_file "Idle"
    copy_update_state_file "Sync"
    copy_update_state_file "Download"
    copy_update_state_file "ArtifactInstall"
    copy_update_state_file "ArtifactReboot"
    copy_update_state_file "ArtifactCommit"
    copy_update_state_file "ArtifactRollback"
    copy_update_state_file "ArtifactRollbackReboot"
    copy_update_state_file "ArtifactFailure"

    # Create a flag to indicate that the provides inventory needs to be reported.
    # The `mender-update show-provides` command is CPU intensive, so to avoid excessive CPU usage,
    # we generate a flag to trigger the inventory report only when an artifact is installed.
    # This flag is set during the `Download` state of the State Script, ensuring it runs
    # for any artifact installation, including stand-alone installations.
    cp SetInventoryProvidesReportFlag ${MENDER_STATE_SCRIPTS_DIR}/Download_Leave_90_SetInventoryProvidesReportFlag
}
