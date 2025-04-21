do_install:append:vtc1920() {
    # The wireless LAN is recognized as "wlp0s20f0u*" and
    # its index changes depending on the connected port,
    # so it is not supported by default.
    sed -i \
    -e 's/$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/\
      - key: modem[all]\
        value_type: json\
      - key: net.if.out[enp1s0,bytes]\
        value_type: int64\
      - key: net.if.in[enp1s0,bytes]\
        value_type: int64\
      - key: net.if.out[wwp0s20f0u3i8,bytes]\
        value_type: int64\
      - key: net.if.in[wwp0s20f0u3i8,bytes]\
        value_type: int64\
$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/'\
    -e 's/$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/\
      - dst_key: mmcli\
        src_key: '\'\"modem[all]\"\''\
      - dst_key: ip.enp1s0.stats64.tx.bytes\
        src_key: '\'\"net.if.out[enp1s0,bytes]\"\''\
      - dst_key: ip.enp1s0.stats64.rx.bytes\
        src_key: '\'\"net.if.in[enp1s0,bytes]\"\''\
      - dst_key: ip.enp1s0.stats64.tx.bps\
        src_key: '\'\"net.if.out[enp1s0,bytes]\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 8\
        - change_per_interval:\
            interval_sec: 1\
      - dst_key: ip.enp1s0.stats64.rx.bps\
        src_key: '\'\"net.if.in[enp1s0,bytes]\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 8\
        - change_per_interval:\
            interval_sec: 1\
      - dst_key: ip.wwp0s20f0u3i8.stats64.tx.bytes\
        src_key: '\'\"net.if.out[wwp0s20f0u3i8,bytes]\"\''\
      - dst_key: ip.wwp0s20f0u3i8.stats64.rx.bytes\
        src_key: '\'\"net.if.in[wwp0s20f0u3i8,bytes]\"\''\
      - dst_key: ip.wwp0s20f0u3i8.stats64.tx.bps\
        src_key: '\'\"net.if.out[wwp0s20f0u3i8,bytes]\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 8\
        - change_per_interval:\
            interval_sec: 1\
      - dst_key: ip.wwp0s20f0u3i8.stats64.rx.bps\
        src_key: '\'\"net.if.in[wwp0s20f0u3i8,bytes]\"\''\
        value_converters:\
        - scaler:\
            scale_factor: 8\
        - change_per_interval:\
            interval_sec: 1\
$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/' ${D}${sysconfdir}/dc_conf/zabbix_inventory.yml
}