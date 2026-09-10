do_install:append:vtc1920() {
    sed -i \
    -e 's/$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/\
      - key: modem[all]\
        value_type: json\
$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/'\
    -e 's/$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/\
      - dst_key: mmcli\
        src_key: '\'\"modem[all]\"\''\
$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/' ${D}${sysconfdir}/dc_conf/zabbix_inventory.yml
}