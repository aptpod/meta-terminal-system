FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://mender-standalone-update.sh \
          "

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

RDEPENDS:${PN} += "bash"
FILES:${PN} = "${bindir}"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/mender-standalone-update.sh ${D}${bindir}
}
