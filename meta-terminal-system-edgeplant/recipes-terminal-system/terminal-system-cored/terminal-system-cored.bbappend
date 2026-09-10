FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:edgeplant-r1 = " \
           file://default/intdash/agent.yaml.append \
           file://diagnostic-monitors/diskusage_media_sd.yml \
           file://docker-compose/measurement/services/Analog_(Onboard).yml \
           file://docker-compose/measurement/services/IMU_Accel_(Onboard).yml \
           file://docker-compose/measurement/services/IMU_Gyro_(Onboard).yml \
"

do_install:append:edgeplant-r1() {
    cat ${WORKDIR}/band-preset/em7431.yml \
        ${WORKDIR}/band-preset/em05gfa.yml \
        ${WORKDIR}/band-preset/rm520n-gl.yml \
        > ${D}${sysconfdir}/core/band-preset.yml
}
