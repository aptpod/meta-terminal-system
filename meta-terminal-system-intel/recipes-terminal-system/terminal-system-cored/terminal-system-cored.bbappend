FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:intel-x86-common = " \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera_x4.yml \
"
SRC_URI:append:vtc1920 = " \
           file://default/intdash/agent.yaml.append \
           file://docker-compose/measurement/services/Audio_(Onboard).yml \
"
