# Use the system CA store, which follows the ca-certificates recipe (as Debian does).
do_install:append:class-target() {
    cacert=${D}${PYTHON_SITEPACKAGES_DIR}/certifi/cacert.pem
    [ -f "$cacert" ] || bbfatal "certifi/cacert.pem is not at $cacert; cannot point it to the system CA store"
    ln -sf ${sysconfdir}/ssl/certs/ca-certificates.crt "$cacert"
}

RDEPENDS:${PN}:append:class-target = " ca-certificates"
