FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Use the Compose version that matches the Docker Engine.
# 1. Check Docker Engine version and SRCREV.
#   docker-ce_git.bb https://git.yoctoproject.org/meta-virtualization/tree/recipes-containers/docker/docker-ce_git.bb?h=kirkstone&id=e60f59f3567b78286ea34337dbae468a5f18f1c6
#   > DOCKER_VERSION = "20.10.25-ce"
#   > SRCREV_docker = "791d8ab87747169b4cbfcdf2fd57c81952bae6d5"
# 2. Update EXPECT_DOCKER_REV to SRCREV_docker.
EXPECT_DOCKER_REV = "791d8ab87747169b4cbfcdf2fd57c81952bae6d5"
# 3. Check Compose version.
#   moby releases https://github.com/moby/moby/releases?q=v20.10+Packaging+Updates+Compose&expanded=true
#   > Update Docker Compose to v2.15.1.
# 4. Set the commit hash of the compose tag to SRCREV_compose.
#   https://github.com/docker/compose/releases/tag/v2.15.1
SRCREV_compose = "00c60da331e7a70af922b1afcce5616c8ab6df36"

SRC_URI += "\
    git://github.com/docker/compose;branch=main;name=compose;destsuffix=git/compose;protocol=https \
    ${@bb.utils.contains('TS_FEATURES', 'include-ecr-credentials', 'file://config.json', '', d)} \
    file://daemon.json \
    file://0001-Revert-bugfix-issie-18826-containers-do-not-restart-.patch \
"

inherit goarch

FILES:${PN} += "${ROOT_HOME}"

INSANE_SKIP:${PN} += "already-stripped"

do_compile:prepend() {
    if [ "${SRCREV_docker}" != "${EXPECT_DOCKER_REV}" ]; then
        bbfatal "docker-ce version mismatch detected. Please update SRCREV_compose in docker-ce.bbappend and EXPECT_DOCKER_REV to match docker-ce.bb version."
    fi
}

do_compile[network] = "1"
do_compile:append() {
    cd ${S}/src/import
    ln -sf ${WORKDIR}/git/compose .gopath/src/github.com/docker/compose
    cd ${S}/src/import/.gopath/src/github.com/docker/compose

    # The source repository is located in the downloads folder ($DL_DIR/git2)
    # and is not accessible from the buildx container environment.
    # Use `git repack -a` to copy the source repository objects to the clone repository.
    git repack -a

    if docker buildx inspect yocto_build > /dev/null 2>&1; then
        docker buildx rm yocto_build
    fi
    docker buildx create --use --name yocto_build

    if [ "${TARGET_GOARCH}" = "arm" ]; then
        target_tuple="${TARGET_GOOS}/${TARGET_GOARCH}/v${TARGET_GOARM}"
    else
        target_tuple="${TARGET_GOOS}/${TARGET_GOARCH}"
    fi
    docker buildx bake release --set release.platform=${target_tuple}
}

do_install:append() {
    if ${@bb.utils.contains('TS_FEATURES', 'include-ecr-credentials', 'true', 'false', d)}; then

        [ -n "${TS_AWS_ECR_BASE_URI}"  ] || bbfatal "TS_AWS_ECR_BASE_URI is not set"

        install -d ${D}/${ROOT_HOME}/.docker
        install -m 600 ${WORKDIR}/config.json ${D}/${ROOT_HOME}/.docker/config.json
        sed -i \
            -e 's:@TS_AWS_ECR_BASE_URI@:${TS_AWS_ECR_BASE_URI}:' \
            ${D}/${ROOT_HOME}/.docker/config.json
    fi

    if [ "${TARGET_GOARCH}" = "arm" ]; then
        target_tuple="${TARGET_GOOS}-${TARGET_GOARCH}v${TARGET_GOARM}"
    else
        target_tuple="${TARGET_GOOS}-${TARGET_ARCH}"
    fi

    install -d ${D}/${libexecdir}/docker/cli-plugins
    install -m 755 ${WORKDIR}/git/compose/bin/release/docker-compose-${target_tuple} ${D}/${libexecdir}/docker/cli-plugins/docker-compose

    install -d ${D}/${sysconfdir}/docker
    install -m 644 ${WORKDIR}/daemon.json ${D}/${sysconfdir}/docker/daemon.json
}
