
SUMMARY = "aptpod CAN Transceiver Linux kernel driver"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${WORKDIR}/git/LICENSE;md5=efb5d297687a2bee5b634d4cf7eeb6cb"

inherit module

SRC_URI = "${TS_APT_USBTRX_SRC_URI}"
SRCREV = "${TS_APT_USBTRX_SRCREV}"
PV = "${TS_APT_USBTRX_PV}"

S = "${WORKDIR}/git/module"

# The inherit of module.bbclass will automatically name module packages with
# "kernel-module-" prefix as required by the oe-core build environment.

KERNEL_MODULE_AUTOLOAD = "apt_usbtrx"

FILES:${PN} += " \
	${bindir} \
	${sysconfdir} \
"
MAKE_TARGETS = "netdev"

do_compile:append () {
	cd ${S}/../tools
	oe_runmake -C apt_usbtrx_enablets CC="${CC}" LDFLAGS="${LDFLAGS}"
	oe_runmake -C apt_usbtrx_resetts CC="${CC}" LDFLAGS="${LDFLAGS}"
	oe_runmake -C apt_usbtrx_serial_no CC="${CC}" LDFLAGS="${LDFLAGS}"
}

do_install:append () {
	cd ${S}
	cd ../conf
	mkdir -p ${D}${sysconfdir}/udev/rules.d
	cp -rd 30-apt-usb.rules ${D}${sysconfdir}/udev/rules.d

	cd ../tools
	install -d ${D}${bindir}
	install -m 755 apt_usbtrx_enablets/apt_usbtrx_enablets ${D}${bindir}/apt_usbtrx_enablets
	install -m 755 apt_usbtrx_resetts/apt_usbtrx_resetts ${D}${bindir}/apt_usbtrx_resetts
	install -m 755 apt_usbtrx_serial_no/apt_usbtrx_serial_no ${D}${bindir}/apt_usbtrx_serial_no
	install -m 755 apt_usbtrx_timesync_all.sh ${D}${bindir}/apt_usbtrx_timesync_all.sh
	install -m 755 apt_usbtrx_fwupdate.py ${D}${bindir}/apt_usbtrx_fwupdate.py
}
