FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://docker-compose/measurement/services/EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/EDGEPLANT_USB_Camera_x4.yml \
"
