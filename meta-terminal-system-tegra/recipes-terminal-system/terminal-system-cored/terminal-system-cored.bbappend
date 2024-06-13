FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/H.264_for_EDGEPLANT_USB_Camera_x4.yml \
           file://docker-compose/measurement/services/H.264_NAL_Unit_for_EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/MJPEG_for_EDGEPLANT_USB_Camera.yml \
"
