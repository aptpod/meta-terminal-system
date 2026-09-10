#
# Lists of the terminal system packages
#

TERMINAL_SYSTEM_BASE = "\
    kernel-modules \
    iproute2 \
    bash \
    usbutils \
    wpa-supplicant \
    jq \
    logrotate \
    ppp \
    libgcc \
    libstdc++ \
    glib-networking \
    glibmm  \
    zlib \
    glib-2.0 \
    ca-certificates \
    curl \
    libcurl \
    libpcre \
    libnl \
    dnsmasq \
    iptables \
    libusb1 \
    libusb-compat \
    bridge-utils \
    sudo \
    rsyslog \
    less \
    tree \
    iputils-ping \
    util-linux-hwclock \
    e2fsprogs-e2fsck \
    e2fsprogs-dumpe2fs \
    coreutils \
    procps \
    python3-pyserial \
    esptool \
    glibc-utils \
    gpsd gps-utils \
    chrony chronyc \
"

TERMINAL_SYSTEM_CORE = "\
    device-inventory \
    login-users \
    terminal-system-files \
    terminal-system-cored \
"

TERMINAL_SYSTEM_NETWORK = "\
    libqmi \
    modemmanager \
    networkmanager \
    hostapd \
    bind-utils \
    cellular-module-init \
"

TERMINAL_SYSTEM_CONNECTOR = "\
    kernel-modules-apt-usbtrx \
    kernel-modules-pcan \
    alsa-utils \
    alsa-tools \
    can-utils \
"

TERMINAL_SYSTEM_DOCKER = "\
    docker \
    docker-archive-load \
"

TERMINAL_SYSTEM_AWS = "\
    amazon-ecr-credential-helper \
"

TERMINAL_SYSTEM_MENDER = "\
    mender-connect \
    mender-configure \
    ${@bb.utils.contains('TS_FEATURES', 'mender-binary-delta', 'mender-binary-delta', '', d)} \
    mender-update-module-custom \
    mender-terminal-system-state-scripts \
    mender-standalone-update \
"
