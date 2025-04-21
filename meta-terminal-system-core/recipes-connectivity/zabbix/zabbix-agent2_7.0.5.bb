SUMMARY = "Open-source monitoring solution for your IT infrastructure"
DESCRIPTION = "\
ZABBIX is software that monitors numerous parameters of a network and the \
health and integrity of servers. ZABBIX uses a flexible notification \
mechanism that allows users to configure e-mail based alerts for virtually \
any event. This allows a fast reaction to server problems. ZABBIX offers \
excellent reporting and data visualisation features based on the stored \
data. This makes ZABBIX ideal for capacity planning. \
\
ZABBIX supports both polling and trapping. All ZABBIX reports and \
statistics, as well as configuration parameters are accessed through a \
web-based front end. A web-based front end ensures that the status of \
your network and the health of your servers can be assessed from any \
location. Properly configured, ZABBIX can play an important role in \
monitoring IT infrastructure. This is equally true for small \
organisations with a few servers and for large companies with a \
multitude of servers."
HOMEPAGE = "http://www.zabbix.com/"
SECTION = "Applications/Internet"
LICENSE = "AGPL-3.0-only"
LIC_FILES_CHKSUM = "file://COPYING;md5=eb1e647870add0502f8f010b19de32af"
DEPENDS  = "go openssl libpcre zlib"

PACKAGE_ARCH = "${MACHINE_ARCH}"

SRC_URI = "https://cdn.zabbix.com/zabbix/sources/stable/7.0/zabbix-${PV}.tar.gz \
    file://0001-Fix-configure.ac.patch \
    file://0001-Fix-Makefile-to-use-go-specified-by-variable.patch \
    file://zabbix_agent2.conf \
    file://zabbix-agent2.service \
"
SRC_URI[sha256sum] = "215301b6e089a685a2fabcca17fc65e5766d42d2079174b65a1bf28df7679692"

inherit go-mod autotools-brokensep linux-kernel-base pkgconfig systemd useradd

GO_IMPORT = "go"

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "zabbix-agent2.service"
SYSTEMD_AUTO_ENABLE = "enable"

USERADD_PACKAGES = "${PN}"
GROUPADD_PARAM:${PN} = "-r zabbix"
USERADD_PARAM:${PN} = "-r -g zabbix -d /var/lib/zabbix \
    -s /sbin/nologin zabbix \
"

KERNEL_VERSION = "${@get_kernelversion_headers('${STAGING_KERNEL_DIR}')}"

EXTRA_OECONF = " \
    --sysconfdir=${sysconfdir}/zabbix \
    --enable-dependency-tracking \
    --enable-agent2 \
    --with-ssh2 \
    --with-zlib \
    --with-libpthread \
    --with-libpcre=${STAGING_EXECPREFIXDIR} \
"
CFLAGS:append = " -pthread"

S = "${WORKDIR}/zabbix-${PV}"

FILES:${PN} = " \
    ${sysconfdir}/zabbix/zabbix_agent2.conf \
    ${sysconfdir}/zabbix/zabbix_agent2.d/plugins.d/docker.conf \
    ${sysconfdir}/zabbix/zabbix_agent2.d/plugins.d/smart.conf \
    ${sbindir}/zabbix_agent2 \
"

do_configure:prepend() {
    export KERNEL_VERSION="${KERNEL_VERSION}"
}

do_compile() {
    oe_runmake -C ${S}
}

do_install:append() {
    install -m 0644 ${WORKDIR}/zabbix_agent2.conf ${D}${sysconfdir}/zabbix/zabbix_agent2.conf
    find ${D}${sysconfdir}/zabbix/zabbix_agent2.d/plugins.d -type f ! -name 'docker.conf' ! -name 'smart.conf' -delete
    rm -rf ${D}${sysconfdir}/zabbix/zabbix_agentd.conf ${D}${sysconfdir}/zabbix/zabbix_agentd.conf.d ${D}${sbindir}/zabbix_agentd
    rm -rf ${D}${libdir}
    if ${@bb.utils.contains('DISTRO_FEATURES','systemd','true','false',d)}; then
        install -d ${D}${systemd_unitdir}/system
        install -m 0644 ${WORKDIR}/zabbix-agent2.service ${D}${systemd_unitdir}/system/
        sed -i -e 's#@SBINDIR@#${sbindir}#g' ${D}${systemd_unitdir}/system/zabbix-agent2.service
    fi
}
