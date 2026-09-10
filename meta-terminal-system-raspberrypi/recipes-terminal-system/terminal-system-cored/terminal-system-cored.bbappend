FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
           file://diagnostic-monitors/vcgencmd_throttled.yml \
           file://docker-compose/measurement/services/EDGEPLANT_USB_Camera.yml \
           file://docker-compose/measurement/services/Camera/fps_edgeplant_usb_camera.sh \
           file://docker-compose/measurement/services/Camera/fps_edgeplant_usb_3.0_camera_ip67.sh \
"
SRC_URI:append:raspberrypi4-64 = " \
           file://default/intdash/agent.yaml.append \
           file://docker-compose/measurement/services/Raspberry_Pi_Camera.yml \
           file://docker-compose/measurement/services/Camera/fps_raspberry_pi_camera.sh \
"
