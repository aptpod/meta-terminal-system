ILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# TODO: arm-32bit binaries have not been released
SRC_URI = "${@bb.utils.contains('TS_FEATURES', 'include-ecr-credentials', 'file://docker-credential-ecr-login-default', '', d)}"
SRC_URI:append:aarch64 = "\
    https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${PV}/linux-arm64/docker-credential-ecr-login;name=bin \
"
SRC_URI[bin.sha256sum] = "760ecd36acf720cfe6a6ddb6fb20a32845e8886ea2e5333441c4bcca0a1d9620"

HOMEPAGE = "https://github.com/awslabs/amazon-ecr-credential-helper"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

S = "${WORKDIR}"

INSANE_SKIP:${PN} += "already-stripped"

do_configure[noexec] = "1"
do_compile[noexec] = "1"

RDEPENDS:${PN} += "bash"

FILES:${PN} += "${bindir}"

do_install() {
    install -d ${D}${bindir}
    install -m 755 ${WORKDIR}/docker-credential-ecr-login ${D}${bindir}/

    if ${@bb.utils.contains('TS_FEATURES', 'include-ecr-credentials', 'true', 'false', d)}; then

        [ -n "${TS_AWS_CREDS_DEF_ACCESS_KEY_ID}"  ] || bbfatal "TS_AWS_CREDS_DEF_ACCESS_KEY_ID is not set"
        [ -n "${TS_AWS_CREDS_DEF_SECRET_ACCESS_KEY}"  ] || bbfatal "TS_AWS_CREDS_DEF_SECRET_ACCESS_KEY is not set"

        install -m 755 ${WORKDIR}/docker-credential-ecr-login-default ${D}${bindir}/

        sed -i \
            -e 's:@TS_AWS_CREDS_DEF_ACCESS_KEY_ID@:${TS_AWS_CREDS_DEF_ACCESS_KEY_ID}:' \
            -e 's:@TS_AWS_CREDS_DEF_SECRET_ACCESS_KEY@:${TS_AWS_CREDS_DEF_SECRET_ACCESS_KEY}:' \
            ${D}${bindir}/docker-credential-ecr-login-default
    fi
}
