FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

def if_kernel_recipe(if_true, if_false, d):
    if d.getVar('PREFERRED_PROVIDER_virtual/kernel') == d.getVar('PN'):
        return if_true
    else:
        return if_false

SRC_URI:append = " \
    ${@if_kernel_recipe('file://bbr.cfg', '', d)} \
    ${@if_kernel_recipe('file://m5stack.cfg', '', d)} \
    ${@if_kernel_recipe('file://qmi.cfg', '', d)} \
    ${@if_kernel_recipe('file://0001-fix-uvc-max-payload-transfer-size-for-edgeplant-usb-camera.patch', '', d)} \
"
# Remove patch as it has already been applied in meta-edgeplant
SRC_URI:remove:jasmine = " \
    ${@if_kernel_recipe('file://0001-fix-uvc-max-payload-transfer-size-for-edgeplant-usb-camera.patch', '', d)} \
"
