FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SUMMARY = "Recipe for Terminal System Login Users"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = ""
SRC_URI:append:mender-image = " \
    file://InstallLoginUsersUpperdir \
    file://MigrateLoginUsersPasswd \
"

S = "${WORKDIR}"

PR = "r0"

inherit useradd mender-state-scripts

DEPENDS += " docker-ce "

USER_ADMIN = "admin"
# maint user can only connected via remote ssh tunnel (see 'sshd_config' modified by openssh_%.bbappend)
USER_MAINT = "maint"
USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = " \
    -G adm,audio,video,docker ${USER_ADMIN}; \
    -G adm,audio,video,docker ${USER_MAINT}; \
    user \
"

FILES:${PN} = " \
    /home/${USER_ADMIN}/.ssh \
    /home/${USER_MAINT}/.ssh \
"
FILES:${PN}:append:mender-image = " \
    /data/overlay/home/${USER_ADMIN}/.ssh \
    /data/overlay/home/${USER_MAINT}/.ssh \
"

do_compile:append:mender-image() {
    cp InstallLoginUsersUpperdir ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_InstallLoginUsersUpperdir
    cp MigrateLoginUsersPasswd ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_MigrateLoginUsersPasswd
}

do_install () {
    install -d -m 0700 -o ${USER_ADMIN} -g ${USER_ADMIN} ${D}/home/${USER_ADMIN}/.ssh
    install -d -m 0700 -o ${USER_MAINT} -g ${USER_MAINT} ${D}/home/${USER_MAINT}/.ssh
}

do_install:append:mender-image() {
    install -d -m 0700 -o ${USER_ADMIN} -g ${USER_ADMIN} ${D}/data/overlay/home/${USER_ADMIN}/.ssh
    install -d -m 0700 -o ${USER_MAINT} -g ${USER_MAINT} ${D}/data/overlay/home/${USER_MAINT}/.ssh
}
