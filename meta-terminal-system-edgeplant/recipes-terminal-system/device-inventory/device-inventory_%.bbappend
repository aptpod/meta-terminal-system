FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

RDEPENDS:${PN}:append:jasmine = " \
    edgeplant-l4t-tools \
"
