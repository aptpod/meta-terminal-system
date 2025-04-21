ILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "${@bb.utils.contains('TS_FEATURES', 'include-ecr-credentials', 'file://docker-credential-ecr-login-default', '', d)} \
           https://amazon-ecr-credential-helper-releases.s3.us-east-2.amazonaws.com/${PV}/linux-${DPKG_ARCH}/docker-credential-ecr-login;name=${DPKG_ARCH}_bin \
"
SRC_URI[arm64_bin.sha256sum] = "76aa3bb223d4e64dd4456376334273f27830c8d818efe278ab6ea81cb0844420"
SRC_URI[amd64_bin.sha256sum] = "dd6bd933e439ddb33b9f005ad5575705a243d4e1e3d286b6c82928bcb70e949a"
# TODO: build from source to support armhf

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
