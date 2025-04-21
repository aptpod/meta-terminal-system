FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://diagnostic-monitors/vcgencmd_throttled.yml \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera_(YUY2).yml \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera.yml \
"
SRC_URI:append:raspberrypi4-64 = " \
           file://default/intdash/agent.yaml.append \
           file://docker-compose/measurement/services/H.264_for_Raspberry_Pi_Camera.yml \
"
