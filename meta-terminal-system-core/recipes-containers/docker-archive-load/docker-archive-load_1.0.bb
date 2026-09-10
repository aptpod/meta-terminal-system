FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI = "file://docker-archive-load.service \
           file://docker-archive-load.sh \
           ${TS_SRC_URI_DOCKER_ARCHIVE_LOAD} \
"

SRC_URI:append:mender-image = " \
    file://state-scripts/ResetDockerArchivePreinstallFlag \
"

LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

inherit systemd mender-state-scripts

RDEPENDS:${PN} += "docker bash"
FILES:${PN} = "${localstatedir}/lib/docker-archive-load \
               ${bindir} \
               ${systemd_system_unitdir} \
"

S = "${WORKDIR}/${TS_RESOURCES_DIR}"

do_compile() {
    :
}
do_compile:append:mender-image() {
    # ArtifactInstall_Leave - Reset preinstall flag on OS update
    cp ${WORKDIR}/state-scripts/ResetDockerArchivePreinstallFlag ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_90_ResetDockerArchivePreinstallFlag
}

do_install() {
    # install pre-install images
    install -d ${D}${localstatedir}/lib/docker-archive-load

    # Create preinstall images list file
    PREINSTALL_LIST="${D}${localstatedir}/lib/docker-archive-load/.preinstall-images"
    touch ${PREINSTALL_LIST}

    for path in ${TS_SRC_URI_DOCKER_ARCHIVE_LOAD}; do
        # remove .docker-archive-load used to avoid unpack
        archive_with_ext="$(basename ${path})"
        archive=${archive_with_ext%.docker-archive-load}
        install -m 0400 ${S}/${archive_with_ext} ${D}${localstatedir}/lib/docker-archive-load/${archive}

        # Record preinstall image filename
        echo "${archive}" >> ${PREINSTALL_LIST}
    done

    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/docker-archive-load.service ${D}${systemd_system_unitdir}

    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/docker-archive-load.sh ${D}${bindir}
}

SYSTEMD_SERVICE:${PN} = "\
docker-archive-load.service \
"
