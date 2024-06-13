FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
             file://0001-fix-change-autoconnect-retry-time-300s-30s.patch \
             file://disable-wifi-scan-rand-mac-address.conf \
             file://no-auto-default.conf \
"

FILES:${PN}:append:mender-image = " \
    /data/overlay${sysconfdir}/NetworkManager/system-connections \
"

PACKAGECONFIG:append = "dhcpcd ppp modemmanager"

do_install:append() {
    install -Dm 0644 ${WORKDIR}/disable-wifi-scan-rand-mac-address.conf ${D}${libdir}/NetworkManager/conf.d/disable-wifi-scan-rand-mac-address.conf
    install -Dm 0644 ${WORKDIR}/no-auto-default.conf ${D}${libdir}/NetworkManager/conf.d/no-auto-default.conf
}

do_install:append:mender-image() {
    install -m 755 -d ${D}/data/overlay${sysconfdir}/NetworkManager/system-connections
}