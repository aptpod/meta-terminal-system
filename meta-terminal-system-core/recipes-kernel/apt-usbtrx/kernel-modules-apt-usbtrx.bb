
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
	oe_runmake CC="${CC}" LDFLAGS="${LDFLAGS}"
}

do_install:append () {
	cd ${S}/../conf
	mkdir -p ${D}${sysconfdir}/udev/rules.d
	cp -rd 30-apt-usb.rules ${D}${sysconfdir}/udev/rules.d

	# tools is installed in ${DESTDIR}/bin
	cd ${S}/../tools
	install -d ${D}${exec_prefix}
	oe_runmake install DESTDIR=${D}${exec_prefix}
}