
SUMMARY = "PCAN Driver for Linux"
LICENSE = "LGPL-2.0-only | GPL-2.0-only"
LIC_FILES_CHKSUM = "file://${WORKDIR}/peak-linux-driver-${PV}/Documentation/COPYING;md5=94d55d512a9ba36caa9b7df079bae19f"

inherit module

SRC_URI = "https://www.peak-system.com/fileadmin/media/linux/files/peak-linux-driver-${PV}.tar.gz \
           file://0001-Makefile.patch \
          "
SRC_URI[md5sum] = "fe83da3b0666bc0669223a6040dd966c"

S = "${WORKDIR}/peak-linux-driver-${PV}/driver"

KERNEL_MODULE_AUTOLOAD = "pcan"

# The inherit of module.bbclass will automatically name module packages with
# "kernel-module-" prefix as required by the oe-core build environment.

FILES:${PN} += "${sysconfdir} ${exec_prefix}/local/bin"
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
}
