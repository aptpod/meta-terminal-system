FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:intel-x86-common = " \
           file://docker-compose/measurement/services/EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/EDGEPLANT_USB_Camera_x4.yml \
"
SRC_URI:append:vtc1920 = " \
           file://default/intdash/agent.yaml.append \
           file://docker-compose/measurement/services/Audio_(Onboard).yml \
"

do_install:append:vtc1920() {
    cat ${WORKDIR}/band-preset/em7431.yml \
        ${WORKDIR}/band-preset/em05gfa.yml \
        ${WORKDIR}/band-preset/rm520n-gl.yml \
        > ${D}${sysconfdir}/core/band-preset.yml
}
