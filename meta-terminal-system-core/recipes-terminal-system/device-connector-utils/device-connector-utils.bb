SUMMARY = "Device Connector Utils"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = "file://${TS_RESOURCES_DIR}/device-connector-utils_${TS_DEB_VERSION_DEVICE_CONNECTOR}_${DPKG_ARCH}.deb"

PV = "${TS_DEB_VERSION_DEVICE_CONNECTOR}"

FILES:${PN} = "${bindir}"

RDEPENDS:${PN} += " \
    alsa-lib \
    alsa-utils \
"
INSANE_SKIP:${PN} += "already-stripped"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

do_install () {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/usr/bin/dc-utils ${D}${bindir}
}
