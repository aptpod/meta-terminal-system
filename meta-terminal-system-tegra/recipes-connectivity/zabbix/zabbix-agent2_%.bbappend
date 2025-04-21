SRC_URI += "git://github.com/aptpod/zabbix-agent2-plugin-tegrastats.git;protocol=https;branch=main;rev=368a7738fe7cab7635e5a7f43b9413433de7ef1a;destsuffix=plugin-tegrastats"

FILES:${PN} += " \
    ${sbindir}/zabbix-agent2-plugin/zabbix-agent2-plugin-tegrastats \
    ${sysconfdir}/zabbix/zabbix_agent2.d/plugins.d/tegrastats.conf \
"

do_compile[network] = "1"
do_compile:append() {
    oe_runmake -C ${WORKDIR}/plugin-tegrastats
}

do_install:append() {
    install -d ${D}${sbindir}/zabbix-agent2-plugin
    install -m 0755 ${WORKDIR}/plugin-tegrastats/target/**/zabbix-agent2-plugin-tegrastats ${D}${sbindir}/zabbix-agent2-plugin/
    install -m 0644 ${WORKDIR}/plugin-tegrastats/tegrastats.conf ${D}${sysconfdir}/zabbix/zabbix_agent2.d/plugins.d/
}

do_rm_work:prepend() {
    ${GO} clean -modcache || true
}