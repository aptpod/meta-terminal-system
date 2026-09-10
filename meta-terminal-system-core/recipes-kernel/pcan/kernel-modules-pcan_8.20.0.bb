
SUMMARY = "PCAN Driver for Linux"
LICENSE = "LGPL-2.0-only | GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${WORKDIR}/peak-linux-driver-${PV}/Documentation/COPYING;md5=94d55d512a9ba36caa9b7df079bae19f"

inherit module

SRC_URI = "https://www.peak-system.com/fileadmin/media/linux/files/peak-linux-driver-${PV}.tar.gz \
           file://0001-Makefile.patch \
           file://70-pcan-persistent-naming.rules \
           file://can-persistent-name-pcan \
          "
SRC_URI[md5sum] = "8901d61d0ac4246226c289577bbb69fa"

S = "${WORKDIR}/peak-linux-driver-${PV}/driver"

KERNEL_MODULE_AUTOLOAD = "pcan"

# The inherit of module.bbclass will automatically name module packages with
# "kernel-module-" prefix as required by the oe-core build environment.

FILES:${PN} += "${sysconfdir} ${exec_prefix}/local/bin ${bindir}"
KERNEL_CC = "${CC}"
MAKE_TARGETS = "netdev"

do_install:append () {
  oe_runmake DESTDIR="${D}" BINDIR="${exec_prefix}/local/bin" install_files install_udev
  sed -i \
    -e 's:# options pcan rxqsize=:options pcan rxqsize=5000:' \
    -e 's:# options pcan txqsize=:options pcan txqsize=999:' \
    -e 's:# options pcan drvclkref=:options pcan drvclkref=1:' \
    -e '$a\\nblacklist peak_usb' \
    "${D}${sysconfdir}/modprobe.d/pcan.conf"

  install -d ${D}${sysconfdir}/udev/rules.d
  install -m 0644 ${WORKDIR}/70-pcan-persistent-naming.rules ${D}${sysconfdir}/udev/rules.d

  install -d ${D}${bindir}
  install -m 0755 ${WORKDIR}/can-persistent-name-pcan ${D}${bindir}/can-persistent-name-pcan
}
