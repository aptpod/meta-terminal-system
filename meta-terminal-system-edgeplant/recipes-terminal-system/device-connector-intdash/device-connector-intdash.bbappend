FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI:append:jasmine = " \
    file://ts2.fw.powermanage.conf \
    file://zabbix_inventory_powermanage.sh \
"

FILES:device-connector-plugins-zabbix-inventory:append:jasmine = " \
    ${sysconfdir}/dc_conf/scripts/zabbix_inventory_powermanage.sh \
    ${sysconfdir}/zabbix/zabbix_agent2.d/device_connector_intdash.d/ts2.fw.powermanage.conf \
"

RDEPENDS:device-connector-plugins-zabbix-inventory:append:jasmine = " \
   edgeplant-l4t-tools \
"

do_install:append:jasmine() {
    sed -i \
    -e 's/$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/\
      - key: modem[all]\
        value_type: json\
      - key: ts2.fw.powermanage\
        value_type: json\
      - key: vfs.fs.size[\/media\/ssd,pused]\
        value_type: float64\
      - key: vfs.fs.size[\/media\/ssd,free]\
        value_type: float64\
      - key: vfs.fs.size[\/media\/ssd,used]\
        value_type: float64\
$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/'\
    -e 's/$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/\
      - dst_key: mmcli\
        src_key: '\'\"modem[all]\"\''\
      - dst_key: firmware.powermanage\
        src_key: '\'\"ts2.fw.powermanage\"\''\
      - dst_key: df.\/media\/ssd.use_percent\
        src_key: '\'\"'vfs.fs.size[\/media\/ssd,pused]'\"\''\
      - dst_key: df.\/media\/ssd.available\
        src_key: '\'\"'vfs.fs.size[\/media\/ssd,free]'\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 0.0009765625\
      - dst_key: df.\/media\/ssd.used\
        src_key: '\'\"'vfs.fs.size[\/media\/ssd,used]'\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 0.0009765625\
$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/' ${D}${sysconfdir}/dc_conf/zabbix_inventory.yml
}