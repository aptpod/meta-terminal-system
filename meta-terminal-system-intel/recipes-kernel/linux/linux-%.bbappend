FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

def if_kernel_recipe(if_true, if_false, d):
    if d.getVar('PREFERRED_PROVIDER_virtual/kernel') == d.getVar('PN'):
        return if_true
    else:
        return if_false

SRC_URI:append:vtc1920 = " \
    ${@if_kernel_recipe('file://onboard-can.cfg', '', d)} \
"
