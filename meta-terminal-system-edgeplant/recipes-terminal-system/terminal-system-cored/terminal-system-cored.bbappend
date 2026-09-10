FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:jasmine = " \
           file://default/intdash/agent.yaml.append \
           file://diagnostic-monitors/diskusage_media_ssd.yml \
           file://diagnostic-monitors/forced_power_off.yml \
           file://diagnostic-monitors/unexpected_power_interruption.yml \
           file://docker-compose/measurement/services/Audio_(Onboard).yml \
"
SRC_URI:append:jasmine:mender-image = " \
           file://state-scripts/MigrateAudioVolumeSettings \
           file://state-scripts/MigrateGpsService \
"

do_install:append:jasmine() {
    cat ${WORKDIR}/band-preset/em7430.yml \
        ${WORKDIR}/band-preset/em7431.yml \
        ${WORKDIR}/band-preset/em05gfa.yml \
        ${WORKDIR}/band-preset/rm520n-gl.yml \
        > ${D}${sysconfdir}/core/band-preset.yml
}

do_compile:append:jasmine:mender-image() {
    cp ${WORKDIR}/state-scripts/MigrateAudioVolumeSettings ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateAudioVolumeSettings
    cp ${WORKDIR}/state-scripts/MigrateGpsService ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateGpsService
}
