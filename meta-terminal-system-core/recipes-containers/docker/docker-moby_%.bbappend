FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}:"

# Use the Compose version that matches the Docker Engine.
# 1. Check Docker Engine version and SRCREV.
#   docker-moby_git.bb https://git.yoctoproject.org/meta-virtualization/tree/recipes-containers/docker/docker-moby_git.bb?h=scarthgap&id=1ff2a1b03cdf2df0f5093f286961d6b3150e0807
#   > DOCKER_VERSION = "25.0.9"
#   > SRCREV_moby = "a926bec8fc91332410133b24f3e9e3f5add13b48"
# 2. Update EXPECT_MOBY_REV to SRCREV_moby.
EXPECT_MOBY_REV = "a926bec8fc91332410133b24f3e9e3f5add13b48"
# 3. Check Compose version.
#   moby releases https://github.com/moby/moby/releases?q=v25.0+Packaging+Updates+Compose&expanded=true
#   docker-ce-packaging PRs https://github.com/docker/docker-ce-packaging/pulls?q=compose+is:merged
#   > Upgrade Compose to v2.24.7.
# 4. Set the commit hash of the compose tag to SRCREV_compose.
#   https://github.com/docker/compose/releases/tag/v2.24.7
SRCREV_compose = "4efb89709ccb9f11ce0b6571a1c4674be37a42b7"

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
    if [ "${SRCREV_moby}" != "${EXPECT_MOBY_REV}" ]; then
        bbfatal "docker-moby version mismatch detected. Please update SRCREV_compose and EXPECT_MOBY_REV in docker-moby.bbappend to match docker-moby.bb version."
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
