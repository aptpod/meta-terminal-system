FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
             file://0001-fix-change-autoconnect-retry-time-300s-30s.patch \
             file://0001-feat-treat-any-HTTP-response-as-online-when-connecti.patch \
             file://disable-wifi-scan-rand-mac-address.conf \
             file://no-auto-default.conf \
             file://99-connectivity.conf \
             file://networkmanager-state.conf \
"

FILES:${PN}:append:mender-image = " \
    /data/overlay${sysconfdir}/NetworkManager/system-connections \
"

FILES:${PN}-daemon += "${nonarch_libdir}/tmpfiles.d/networkmanager-state.conf"

PACKAGECONFIG:append = " dhcpcd ppp modemmanager concheck"
PACKAGECONFIG:remove = "vala"

# The connectivity-check patch (0001-feat-treat-any-HTTP-response-as-online-when-connecti.patch)
# patches nm-connectivity.c, whose surrounding code can change between
# NetworkManager releases. Pin the version this patch was validated against so a
# NetworkManager upgrade fails the build and forces the patch to be re-checked:
#   1. Re-validate the patch against the new NetworkManager source.
#   2. Update EXPECT_NM_VERSION to the new version (PV).
EXPECT_NM_VERSION = "1.46.0"
do_compile:prepend() {
    if [ "${PV}" != "${EXPECT_NM_VERSION}" ]; then
        bbfatal "NetworkManager version changed (${PV} != ${EXPECT_NM_VERSION}). Re-validate the connectivity-check patch and update EXPECT_NM_VERSION."
    fi
}

do_install:append() {
    install -Dm 0644 ${WORKDIR}/disable-wifi-scan-rand-mac-address.conf ${D}${libdir}/NetworkManager/conf.d/disable-wifi-scan-rand-mac-address.conf
    install -Dm 0644 ${WORKDIR}/no-auto-default.conf ${D}${libdir}/NetworkManager/conf.d/no-auto-default.conf
    install -Dm 0644 ${WORKDIR}/99-connectivity.conf ${D}${libdir}/NetworkManager/conf.d/99-connectivity.conf
    install -Dm 0644 ${WORKDIR}/networkmanager-state.conf ${D}${nonarch_libdir}/tmpfiles.d/networkmanager-state.conf
}

do_install:append:mender-image() {
    install -m 755 -d ${D}/data/overlay${sysconfdir}/NetworkManager/system-connections
}