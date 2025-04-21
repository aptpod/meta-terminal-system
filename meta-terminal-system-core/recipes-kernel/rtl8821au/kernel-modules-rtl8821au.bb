
SUMMARY = "rtl8821au Linux kernel module"
LICENSE = "GPL-2.0-only"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b1918d7d89f091725a3188ff95f7c72b"

inherit module

SRC_URI = "git://github.com/morrownr/8821au-20210708.git;protocol=https;branch=main \
           file://0001-Use-modules_install-as-wanted-by-yocto.patch \
          "

# Latest at 2024-11-26
SRCREV = "0b12ea54b7d6dcbfa4ce94eb403b1447565407f1"

S = "${WORKDIR}/git"

# The inherit of module.bbclass will automatically name module packages with
# "kernel-module-" prefix as required by the oe-core build environment.
KERNEL_MODULE_AUTOLOAD = "8821au"

EXTRA_OEMAKE:append = " KSRC=${STAGING_KERNEL_DIR}"
