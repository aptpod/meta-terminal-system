FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " file://mender-connect.conf \
"

do_install:append() {
    # Since the default setting does not configure groups,
    # log in as root and use sudo to start a shell with maint user.
    install -m 600 ${WORKDIR}/mender-connect.conf ${D}/${sysconfdir}/mender/mender-connect.conf
}
