FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://SetInventoryProvidesReportFlag \
          "

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit mender-state-scripts

S = "${WORKDIR}"

do_compile() {
    # Create a flag to indicate that the provides inventory needs to be reported.
    # The `mender-update show-provides` command is CPU intensive, so to avoid excessive CPU usage,
    # we generate a flag to trigger the inventory report only when an artifact is installed.
    # This flag is set during the `Download` state of the State Script, ensuring it runs
    # for any artifact installation, including stand-alone installations.
    cp SetInventoryProvidesReportFlag ${MENDER_STATE_SCRIPTS_DIR}/Download_Leave_90_SetInventoryProvidesReportFlag
}
