FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera_(YUY2).yml \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/H.264_for_Raspberry_Pi_Camera.yml \
"
