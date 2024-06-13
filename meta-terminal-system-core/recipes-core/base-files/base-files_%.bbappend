FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:mender-image = "file://InstallLoginUsersWorkdir"

inherit mender-state-scripts

hostname="terminal-system"

TERMINAL_SYSTEM_OVERLAY = "/data/overlay"
TERMINAL_SYSTEM_OVERLAY_WORK = "${TERMINAL_SYSTEM_OVERLAY}/work"

USER_ADMIN = "admin"
USER_MAINT = "maint"
DOT_SSH_DIR_ADMIN = "/home/${USER_ADMIN}/.ssh"
DOT_SSH_DIR_MAINT = "/home/${USER_MAINT}/.ssh"

do_compile:append:mender-image() {
    # In 1.0.0-beta.1, since the workdir does not exist,
    # it is created with a state script during the OS update.
    cp InstallLoginUsersWorkdir ${MENDER_STATE_SCRIPTS_DIR}/ArtifactInstall_Leave_30_InstallLoginUsersWorkdir
}

do_install_bind_mount_var_lib() {
    echo "# bind mount of data partition" >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/lib/core   /var/lib/core   none bind,x-systemd.requires-mounts-for=/data 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/lib/docker /var/lib/docker none bind,x-systemd.requires-mounts-for=/data 0 0 >> ${D}${sysconfdir}/fstab
}

do_install:append() {
    echo "# overlay mount of data partition" >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" overlay ${sysconfdir} overlay x-systemd.requires-mounts-for=/data,lowerdir=${sysconfdir},upperdir=${TERMINAL_SYSTEM_OVERLAY}${sysconfdir},workdir=${TERMINAL_SYSTEM_OVERLAY_WORK}${sysconfdir} 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" overlay ${DOT_SSH_DIR_ADMIN} overlay x-systemd.requires-mounts-for=/data,lowerdir=${DOT_SSH_DIR_ADMIN},upperdir=${TERMINAL_SYSTEM_OVERLAY}${DOT_SSH_DIR_ADMIN},workdir=${TERMINAL_SYSTEM_OVERLAY_WORK}${DOT_SSH_DIR_ADMIN} 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" overlay ${DOT_SSH_DIR_MAINT} overlay x-systemd.requires-mounts-for=/data,lowerdir=${DOT_SSH_DIR_MAINT},upperdir=${TERMINAL_SYSTEM_OVERLAY}${DOT_SSH_DIR_MAINT},workdir=${TERMINAL_SYSTEM_OVERLAY_WORK}${DOT_SSH_DIR_MAINT} 0 0 >> ${D}${sysconfdir}/fstab
    # lowerdir and upperdir are created with recipes that use directories
    install -m 755 -d ${D}${TERMINAL_SYSTEM_OVERLAY_WORK}${sysconfdir}
    install -m 700 -d ${D}${TERMINAL_SYSTEM_OVERLAY_WORK}${DOT_SSH_DIR_ADMIN}
    install -m 700 -d ${D}${TERMINAL_SYSTEM_OVERLAY_WORK}${DOT_SSH_DIR_MAINT}

    echo "# bind mount of data partition" >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/cache /var/cache none bind,x-systemd.requires-mounts-for=/data 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/log   /var/log   none bind,x-systemd.requires-mounts-for=/data,x-systemd.before=systemd-journald.service,x-systemd.before=systemd-update-utmp.service 0 0 >> ${D}${sysconfdir}/fstab
    do_install_bind_mount_var_lib
}