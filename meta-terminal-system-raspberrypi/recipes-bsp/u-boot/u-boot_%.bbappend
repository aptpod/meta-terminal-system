FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-Set-CONFIG_BOOTDELAY-to-2.patch \
"
