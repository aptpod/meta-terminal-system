SYSTEMD_AUTO_ENABLE="disable"

do_install:append () {

	# Workaround for use with systemd-resolved. see, https://unix.stackexchange.com/a/319501.
    sed -i 's/#bind-interfaces/bind-interfaces/' ${D}${sysconfdir}/dnsmasq.conf
    if [ -f ${D}${sysconfdir}/dbus-1/system.d/dnsmasq.conf ]; then
        sed -i 's/#bind-interfaces/bind-interfaces/' ${D}${sysconfdir}/dbus-1/system.d/dnsmasq.conf
    fi

    # Enable systemd-resolved stub mode
    rm  ${D}${sysconfdir}/systemd/resolved.conf.d/dnsmasq-resolved.conf
}
