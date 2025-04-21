SUMMARY = "A Python-based, open-source, platform-independent utility to communicate with the ROM bootloader in Espressif chips."
HOMEPAGE = "https://github.com/espressif/esptool"
LICENSE = "GPL-2.0-or-later"
LIC_FILES_CHKSUM = "file://LICENSE;md5=b234ee4d69f5fce4486a80fdaf4a4263"

SRC_URI = "git://github.com/espressif/esptool.git;protocol=https;branch=master"
SRCREV = "bff93341542e19ac83d2693ccd08598828c44a21"

S = "${WORKDIR}/git"

inherit setuptools3

RDEPENDS:${PN} += " \
	python3-bitstring \
	python3-cryptography \
	python3-ecdsa \
	python3-pyserial \
	python3-pyyaml \
	python3-intelhex \
"
