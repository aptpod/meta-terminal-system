FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SUMMARY = "Recipe for Terminal System Login Users"
LICENSE = "Apache-2.0"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/Apache-2.0;md5=89aea4e17d99a7cacdbeed46a0096b10"

SRC_URI = ""

S = "${WORKDIR}"

PR = "r0"

inherit useradd

USER_ADMIN = "admin"
# maint user can only connected via remote ssh tunnel (see 'sshd_config' modified by openssh_%.bbappend)
USER_MAINT = "maint"
USERADD_PACKAGES = "${PN}"
USERADD_PARAM:${PN} = " \
    -G adm,audio,video ${USER_ADMIN}; \
    -G adm,audio,video ${USER_MAINT} \
"

FILES:${PN} = " \
    /home/${USER_ADMIN} \
    /home/${USER_MAINT} \
"
FILES:${PN}:append:mender-image = " \
    /data/overlay/home/${USER_ADMIN} \
    /data/overlay/home/${USER_MAINT} \
    /data/overlay${ROOT_HOME} \
    /data/overlay/work/home/${USER_ADMIN} \
    /data/overlay/work/home/${USER_MAINT} \
    /data/overlay/work${ROOT_HOME} \
"

do_install () {
    # Create home directories with correct ownership first
    install -d -m 0755 -o ${USER_ADMIN} -g ${USER_ADMIN} ${D}/home/${USER_ADMIN}
    install -d -m 0755 -o ${USER_MAINT} -g ${USER_MAINT} ${D}/home/${USER_MAINT}
    # Then create .ssh subdirectories
    install -d -m 0700 -o ${USER_ADMIN} -g ${USER_ADMIN} ${D}/home/${USER_ADMIN}/.ssh
    install -d -m 0700 -o ${USER_MAINT} -g ${USER_MAINT} ${D}/home/${USER_MAINT}/.ssh
}

do_install:append:mender-image() {
    # Create upperdir and workdir with correct ownership for overlayfs
    install -d -m 0755 -o ${USER_ADMIN} -g ${USER_ADMIN} ${D}/data/overlay/home/${USER_ADMIN}
    install -d -m 0755 -o ${USER_ADMIN} -g ${USER_ADMIN} ${D}/data/overlay/work/home/${USER_ADMIN}
    install -d -m 0755 -o ${USER_MAINT} -g ${USER_MAINT} ${D}/data/overlay/home/${USER_MAINT}
    install -d -m 0755 -o ${USER_MAINT} -g ${USER_MAINT} ${D}/data/overlay/work/home/${USER_MAINT}
    install -d -m 0700 ${D}/data/overlay${ROOT_HOME}
    install -d -m 0700 ${D}/data/overlay/work${ROOT_HOME}
}
