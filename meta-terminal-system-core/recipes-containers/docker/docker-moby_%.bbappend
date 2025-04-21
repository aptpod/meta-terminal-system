FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Use the Compose version that matches the Docker Engine.
# 1. Check Docker Engine version and SRCREV.
#   docker-moby_git.bb https://git.yoctoproject.org/meta-virtualization/tree/recipes-containers/docker/docker-moby_git.bb?h=scarthgap&id=ee27999aa1e0f863f140d079c2659ea15c895cd5
#   > DOCKER_VERSION = "25.0.3"
#   > SRCREV_moby = "f417435e5f6216828dec57958c490c4f8bae4f98"
# 2. Update EXPECT_MOBY_REV to SRCREV_moby.
EXPECT_MOBY_REV = "f417435e5f6216828dec57958c490c4f8bae4f98"
# 3. Check Compose version.
#   moby releases https://github.com/moby/moby/releases?q=v25.0+Packaging+Updates+Compose&expanded=true
#   > Upgrade Compose to v2.24.5.
# 4. Set the commit hash of the compose tag to SRCREV_compose.
#   https://github.com/docker/compose/releases/tag/v2.24.5
SRCREV_compose = "8fdd45cd4ce0035968efef3cae44529690fbea60"

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
        bbfatal "docker-moby version mismatch detected. Please update SRCREV_compose in docker-moby.bbappend and EXPECT_DOCKER_REV to match docker-moby.bb version."
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
