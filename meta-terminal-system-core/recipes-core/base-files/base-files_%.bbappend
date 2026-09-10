FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://90-terminal-system-path.sh"

hostname="terminal-system"

TERMINAL_SYSTEM_OVERLAY = "/data/overlay"
TERMINAL_SYSTEM_OVERLAY_WORK = "${TERMINAL_SYSTEM_OVERLAY}/work"

USER_ADMIN = "admin"
USER_MAINT = "maint"
HOME_DIR_ROOT = "${ROOT_HOME}"
HOME_DIR_ADMIN = "/home/${USER_ADMIN}"
HOME_DIR_MAINT = "/home/${USER_MAINT}"
MENDER_CONFIGURE_DIR = "${libdir}/mender-configure"

do_install_bind_mount_var_lib() {
    # Create mount point directories for bind mounts in read-only rootfs
    install -d ${D}/var/lib/core
    install -d ${D}/var/lib/docker

    # Mount /var/lib/* after var-volatile-lib.service to ensure bind mounts are placed
    # on top of the overlayfs. This is required for read-only-rootfs where /var/lib is
    # mounted as overlayfs. Without this ordering, overlayfs would hide the bind mounts,
    # causing /var/lib/docker to access through tmpfs instead of /data partition.
    echo "# bind mount of data partition" >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/lib/core   /var/lib/core   none bind,x-systemd.requires-mounts-for=/data,x-systemd.after=var-volatile-lib.service 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/lib/docker /var/lib/docker none bind,x-systemd.requires-mounts-for=/data,x-systemd.after=var-volatile-lib.service 0 0 >> ${D}${sysconfdir}/fstab
}

do_install:append() {
    echo "# overlay mount of data partition" >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" overlay ${HOME_DIR_ROOT} overlay x-systemd.requires-mounts-for=/data,lowerdir=${HOME_DIR_ROOT},upperdir=${TERMINAL_SYSTEM_OVERLAY}${HOME_DIR_ROOT},workdir=${TERMINAL_SYSTEM_OVERLAY_WORK}${HOME_DIR_ROOT} 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" overlay ${HOME_DIR_ADMIN} overlay x-systemd.requires-mounts-for=/data,lowerdir=${HOME_DIR_ADMIN},upperdir=${TERMINAL_SYSTEM_OVERLAY}${HOME_DIR_ADMIN},workdir=${TERMINAL_SYSTEM_OVERLAY_WORK}${HOME_DIR_ADMIN} 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" overlay ${HOME_DIR_MAINT} overlay x-systemd.requires-mounts-for=/data,lowerdir=${HOME_DIR_MAINT},upperdir=${TERMINAL_SYSTEM_OVERLAY}${HOME_DIR_MAINT},workdir=${TERMINAL_SYSTEM_OVERLAY_WORK}${HOME_DIR_MAINT} 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" overlay ${MENDER_CONFIGURE_DIR} overlay x-systemd.requires-mounts-for=/data,lowerdir=${MENDER_CONFIGURE_DIR},upperdir=${TERMINAL_SYSTEM_OVERLAY}${MENDER_CONFIGURE_DIR},workdir=${TERMINAL_SYSTEM_OVERLAY_WORK}${MENDER_CONFIGURE_DIR} 0 0 >> ${D}${sysconfdir}/fstab
    # Note: ownership for home directories will be set by login-users recipe
    # This recipe does not inherit useradd class, so users (admin/maint) don't exist at build time.
    # Therefore, we cannot use -o/-g options here to set ownership for home overlay directories.
    # login-users recipe inherits useradd and creates overlay directories with correct ownership.

    echo "# bind mount of data partition" >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/cache /var/cache none bind,x-systemd.requires-mounts-for=/data 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/log   /var/log   none bind,x-systemd.requires-mounts-for=/data,x-systemd.before=systemd-journald.service,x-systemd.before=systemd-update-utmp.service 0 0 >> ${D}${sysconfdir}/fstab
    # Persist dhcpcd state (DUID/lease) on /data so the DHCP client-id survives
    # reboots and OTA updates. Not in do_install_bind_mount_var_lib (SD/SSD
    # machines override it); the mount point is shipped by the dhcpcd package.
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/lib/dhcpcd /var/lib/dhcpcd none bind,x-systemd.requires-mounts-for=/data,x-systemd.after=var-volatile-lib.service 0 0 >> ${D}${sysconfdir}/fstab
    # Persist NetworkManager state (secret_key) on /data so the IPv6
    # stable-privacy address survives reboots and OTA updates. Same placement
    # rationale as dhcpcd above; the mount point is shipped by networkmanager-daemon.
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" /data/var/lib/NetworkManager /var/lib/NetworkManager none bind,x-systemd.requires-mounts-for=/data,x-systemd.after=var-volatile-lib.service 0 0 >> ${D}${sysconfdir}/fstab
    do_install_bind_mount_var_lib

    # Add tmpfs mount for /media and /mnt to support dynamic mount points in read-only-rootfs
    # /media: for USB auto-mount, SSD mounting (jasmine), and SD card mounting (edgeplant-r1)
    # /mnt: for Mender artifacts that need to mount removable storage (e.g., export-all-measurements)
    echo "# tmpfs mount for media and mnt" >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" tmpfs /media tmpfs defaults,mode=0755 0 0 >> ${D}${sysconfdir}/fstab
    printf "%-20s %-20s %-10s %-21s %-2s %s\n" tmpfs /mnt tmpfs defaults,mode=0755 0 0 >> ${D}${sysconfdir}/fstab

    install -d ${D}${sysconfdir}/profile.d
    install -m 0644 ${WORKDIR}/90-terminal-system-path.sh ${D}${sysconfdir}/profile.d/
}