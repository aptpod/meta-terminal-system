FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
  file://ts2.vcgencmd.conf \
  file://zabbix_inventory_vcgencmd.sh \
"

RDEPENDS:${PN}:append = " \
    userland \
"

do_install:append() {
    sed -i \
    -e 's/$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/\
      - key: ts2.vcgencmd\
        value_type: json\
$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/'\
    -e 's/$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/\
      - dst_key: vcgencmd\
        src_key: '\'\"ts2.vcgencmd\"\''\
$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/' ${D}${sysconfdir}/dc_conf/zabbix_inventory.yml
}