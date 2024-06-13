FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI += "file://rsyslog.conf"

do_install:append () {
	install -m 644 ${WORKDIR}/rsyslog.conf ${D}/${sysconfdir}

	# Remove logrotate settings as they are included in the logrotate recipe
	rm ${D}${sysconfdir}/logrotate.d/logrotate.rsyslog
}
