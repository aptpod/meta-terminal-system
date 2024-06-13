SUMMARY = "Mender Custom Update Module"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = " \
    file://module \
"

S = "${WORKDIR}"

RDEPENDS:${PN} += " \
    bash \
"

FILES:${PN} += "${datadir}/mender/modules/v3/custom"

inherit allarch

do_install() {
    install -d ${D}/${datadir}/mender/modules/v3
    install -m 755 ${S}/module/custom ${D}/${datadir}/mender/modules/v3/custom
}
