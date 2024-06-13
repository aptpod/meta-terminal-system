FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:jasmine = " \
    file://rtl8821au.cfg \
"
