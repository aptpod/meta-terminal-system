FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

SRC_URI += "\
    file://0001-rtl871xdrv-hostapd.conf.patch \
    file://0001-rtlxdrv.patch \
"

do_configure:append() {
    echo CONFIG_DRIVER_RTW=y >> ${B}/.config
}

SYSTEMD_AUTO_ENABLE="disable"