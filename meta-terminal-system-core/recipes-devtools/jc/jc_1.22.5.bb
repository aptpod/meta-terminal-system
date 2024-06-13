SUMMARY = "JSON Convert"
HOMEPAGE = "https://github.com/kellyjonbrazil/jc"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://LICENSE.md;md5=e1e4c3f1ac5aa48ee23021d045410b6e"

SRC_URI = "git://github.com/kellyjonbrazil/jc.git;protocol=https;branch=master"
SRCREV = "b0d6a7307ca7644ba7daf37a28ca3544aa344837"

S = "${WORKDIR}/git"

inherit setuptools3

RDEPENDS:${PN} += " \
    python3 \
    python3-ruamel-yaml \
    python3-xmltodict \
    python3-pygments \
"
