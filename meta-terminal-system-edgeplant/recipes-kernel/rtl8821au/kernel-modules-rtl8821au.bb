
SUMMARY = "rtl8821au Linux kernel module for WI-U2-433DHP"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=8e68f449de40d4a58bcf2ad6bb841217"

inherit module

SRC_URI = "git://github.com/morrownr/8821au.git;protocol=https;branch=main \
           file://0001-Makefile.patch \
          "

# Latest at 2021-Q2
SRCREV = "a13d6d67b54318afebd34a2e905c3a11d08f01f3"

S = "${WORKDIR}/git"

# The inherit of module.bbclass will automatically name module packages with
# "kernel-module-" prefix as required by the oe-core build environment.

KERNEL_MODULE_AUTOLOAD = "8821au"

FILES:${PN} += "${sysconfdir}"
