do_install:append () {
    sed -i \
        -e "/ExecStart=/i ExecCondition=/bin/sh -c '/usr/bin/cored generate gpsd-env >${sysconfdir}/default/gpsd.default'" \
        -e '/ExecStart=/i ExecStartPre=/bin/sh -c "eval $(/usr/bin/cored generate gps-init)"' \
        ${D}${systemd_unitdir}/system/gpsd.service
}

SYSTEMD_SERVICE:${PN} += " ${BPN}.service"
