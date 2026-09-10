FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://gpsd-wait-device \
            file://restart.conf \
"

PACKAGECONFIG[dbus] = "dbus_export='true',dbus_export='false',dbus"

FILES:${PN} += "${systemd_unitdir}/system/gpsd.service.d"

do_install:append () {
    install -D -m 0755 ${WORKDIR}/gpsd-wait-device ${D}${bindir}/gpsd-wait-device

    sed -i \
        -e "/ExecStart=/i ExecCondition=/bin/sh -c '/usr/bin/cored generate gpsd-env >${sysconfdir}/default/gpsd.default'" \
        -e "/ExecStart=/i ExecStartPre=/usr/bin/gpsd-wait-device" \
        -e '/ExecStart=/i ExecStartPre=/bin/sh -c "eval $(/usr/bin/cored generate gps-init)"' \
        ${D}${systemd_unitdir}/system/gpsd.service

    install -D -m 0644 ${WORKDIR}/restart.conf ${D}${systemd_unitdir}/system/gpsd.service.d/restart.conf

    # gpsd's scons silently ignores unknown options, so a renamed dbus_export
    # would re-enable the export without failing the build. Only a dynamically
    # linked libdbus is caught here. Drop this once upstream dbusexport.c
    # flushes its send queue.
    needed=$(${READELF} -d ${D}${sbindir}/gpsd) || bbfatal "readelf failed on ${D}${sbindir}/gpsd"
    case "$needed" in
        *libdbus*) bbfatal "gpsd links libdbus: the dbus PACKAGECONFIG no longer disables the D-Bus export" ;;
    esac
}

SYSTEMD_SERVICE:${PN} += " ${BPN}.service"
