FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append = " \
	file://10-silence.conf \
	file://0001-fix-Change-Before-and-After-of-systemd-machine-id-co.patch \
	file://0001-fix-ExecStop-of-systemd-update-utmp.service-is-not-e.patch \
"

FILES:${PN}:append = " \
	${sysconfdir}/systemd/system/run-docker-.mount.d/10-silence.conf \
"
FILES:${PN}:append:mender-systemd = " \
	/data/var/log/journal \
"

PACKAGECONFIG:remove ="networkd"

do_install:append () {
	# Change NTP Server
	sed -i"" 's/^#NTP=.*/NTP=ntp.intdash.jp/' ${D}${sysconfdir}/systemd/timesyncd.conf

	# Use systemd-resolved stub mode to docker container can switched DNS Server dynamically.
	# Note: We have to set workaround to dnsmasq, https://unix.stackexchange.com/a/319501.
	ln -sf ../run/systemd/resolve/stub-resolv.conf ${D}${sysconfdir}/resolv-conf.systemd

	# Enable BBR
	echo "net.ipv4.tcp_congestion_control=bbr" > ${D}${sysconfdir}/sysctl.d/bbr.conf
	echo "net.core.default_qdisc=fq" >> ${D}${sysconfdir}/sysctl.d/bbr.conf

	# Suppress docker healthcheck mount logs
	# https://github.com/docker/for-linux/issues/679#issuecomment-1004955357
	mkdir -p ${D}${sysconfdir}/systemd/system/run-docker-.mount.d
	install -m 644 ${WORKDIR}/10-silence.conf ${D}${sysconfdir}/systemd/system/run-docker-.mount.d
}

do_install:append:mender-systemd () {
	# /var/log is bind mounted to /data/var/log, see base-files bbappend.
	install -d ${D}/data/var/log/journal
	chown root:systemd-journal ${D}/data/var/log/journal
}
