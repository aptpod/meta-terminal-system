LICENSE = "MIT"
inherit core-image

IMAGE_BASENAME = "${DISTRO}-image"
IMAGE_LINGUAS = " "
IMAGE_FEATURES += " package-management"
EXTRA_IMAGE_FEATURES += "ssh-server-openssh"
TERMINAL_IMAGE_EXTRA_INSTALL = ""

require conf/distro/include/terminal-system-packagelists.inc
IMAGE_INSTALL:append = " \
    ${TERMINAL_SYSTEM_BASE} \
    ${TERMINAL_SYSTEM_CORE} \
    ${TERMINAL_SYSTEM_NETWORK} \
    ${TERMINAL_SYSTEM_CONNECTOR} \
    ${TERMINAL_SYSTEM_DOCKER} \
    ${TERMINAL_SYSTEM_AWS} \
    ${TERMINAL_SYSTEM_MENDER} \
    ${TERMINAL_IMAGE_EXTRA_INSTALL} \
"

TOOLCHAIN_HOST_TASK:append = " nativesdk-cmake"
TOOLCHAIN_TARGET_TASK:append = " openssl-dev libnl-dev kernel-devsrc c-ares-dev util-linux-dev libgcc-dev libstdc++-dev libstdc++-staticdev"
