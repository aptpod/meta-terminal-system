SUMMARY = "A Python-based, open-source, platform-independent utility to communicate with the ROM bootloader in Espressif chips."
HOMEPAGE = "https://github.com/espressif/esptool"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "git://github.com/espressif/esptool.git;protocol=https;branch=master"
SRCREV = "2c69163c21661baa7e103a3e4c133e45c75e5bee"

S = "${WORKDIR}/git"

inherit setuptools3

RDEPENDS:${PN} += " \
	python3-pyserial \
"
