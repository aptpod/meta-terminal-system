FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

def if_kernel_recipe(if_true, if_false, d):
    if d.getVar('PREFERRED_PROVIDER_virtual/kernel') == d.getVar('PN'):
        return if_true
    else:
        return if_false

SRC_URI:append = " \
    ${@if_kernel_recipe('file://bbr.cfg', '', d)} \
    ${@if_kernel_recipe('file://pps.cfg', '', d)} \
    ${@if_kernel_recipe('file://m5stack.cfg', '', d)} \
    ${@if_kernel_recipe('file://qmi.cfg', '', d)} \
    ${@if_kernel_recipe('file://cfs-bandwidth.cfg', '', d)} \
    ${@if_kernel_recipe('file://apt-usbtrx.cfg', '', d)} \
    ${@if_kernel_recipe('file://can.cfg', '', d)} \
    ${@if_kernel_recipe('file://joystick.cfg', '', d)} \
    ${@if_kernel_recipe('file://exfat.cfg', '', d)} \
    ${@if_kernel_recipe('file://0001-fix-uvc-max-payload-transfer-size-for-edgeplant-usb-camera.patch', '', d)} \
    ${@if_kernel_recipe('file://0001-disable-usb3-u1u2-lpm.patch', '', d)} \
    ${@if_kernel_recipe('file://0001-CVE-2025-38472-nf_conntrack-fix-crash-due-to-removal-of-uninitialised-entry.patch', '', d)} \
    ${@if_kernel_recipe('file://0002-CVE-2025-38472-br_netfilter-do-not-check-confirmed-bit-in-br_nf_local_in.patch', '', d)} \
"
