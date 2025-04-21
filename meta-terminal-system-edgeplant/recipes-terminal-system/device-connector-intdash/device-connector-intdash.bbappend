do_install:append:edgeplant-r1() {
    sed -i \
    -e 's/$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/\
      - key: modem[all]\
        value_type: json\
      - key: vfs.fs.size[\/media\/sd,pused]\
        value_type: float64\
      - key: vfs.fs.size[\/media\/sd,free]\
        value_type: float64\
      - key: vfs.fs.size[\/media\/sd,used]\
        value_type: float64\
$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/'\
    -e 's/$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/\
      - dst_key: mmcli\
        src_key: '\'\"modem[all]\"\''\
      - dst_key: df.\/media\/sd.use_percent\
        src_key: '\'\"'vfs.fs.size[\/media\/sd,pused]'\"\''\
      - dst_key: df.\/media\/sd.available\
        src_key: '\'\"'vfs.fs.size[\/media\/sd,free]'\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 0.0009765625\
      - dst_key: df.\/media\/sd.used\
        src_key: '\'\"'vfs.fs.size[\/media\/sd,used]'\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 0.0009765625\
$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/' ${D}${sysconfdir}/dc_conf/zabbix_inventory.yml
}