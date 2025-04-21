RDEPENDS:device-connector-plugins-zabbix-inventory:append = " \
    tegra-tools \
"

do_install:append() {
    sed -i \
    -e 's/$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/\
      - key: tegrastats.emc.usage\
        value_type: int64\
      - key: tegrastats.gpu.usage\
        value_type: int64\
      - key: tegrastats.vic.usage\
        value_type: int64\
      - key: tegrastats.temp.pll\
        value_type: float64\
      - key: tegrastats.temp.mcpu\
        value_type: float64\
      - key: tegrastats.temp.pmic\
        value_type: float64\
      - key: tegrastats.temp.tboard\
        value_type: float64\
      - key: tegrastats.temp.gpu\
        value_type: float64\
      - key: tegrastats.temp.bcpu\
        value_type: float64\
      - key: tegrastats.temp.thermal\
        value_type: float64\
      - key: tegrastats.temp.tdiode\
        value_type: float64\
      - key: tegrastats.power.vdd_sys_gpu[current]\
        value_type: int64\
      - key: tegrastats.power.vdd_sys_soc[current]\
        value_type: int64\
      - key: tegrastats.power.vdd_in[current]\
        value_type: int64\
      - key: tegrastats.power.vdd_sys_cpu[current]\
        value_type: int64\
      - key: tegrastats.power.vdd_sys_ddr[current]\
        value_type: int64\
$(DC_ZABBIX_SRC_INVENTORY_EXTENSION)/'\
    -e 's/$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/\
      - dst_key: tegrastats.emc.usage\
        src_key: '\'\"tegrastats.emc.usage\"\''\
      - dst_key: tegrastats.gpu.usage\
        src_key: '\'\"tegrastats.gpu.usage\"\''\
      - dst_key: tegrastats.vic.usage\
        src_key: '\'\"tegrastats.vic.usage\"\''\
      - dst_key: tegrastats.temperature.PLL\
        src_key: '\'\"tegrastats.temp.pll\"\''\
      - dst_key: tegrastats.temperature.MCPU\
        src_key: '\'\"tegrastats.temp.mcpu\"\''\
      - dst_key: tegrastats.temperature.PMIC\
        src_key: '\'\"tegrastats.temp.pmic\"\''\
      - dst_key: tegrastats.temperature.Tboard\
        src_key: '\'\"tegrastats.temp.tboard\"\''\
      - dst_key: tegrastats.temperature.GPU\
        src_key: '\'\"tegrastats.temp.gpu\"\''\
      - dst_key: tegrastats.temperature.BCPU\
        src_key: '\'\"tegrastats.temp.bcpu\"\''\
      - dst_key: tegrastats.temperature.Thermal\
        src_key: '\'\"tegrastats.temp.thermal\"\''\
      - dst_key: tegrastats.temperature.Tdiode\
        src_key: '\'\"tegrastats.temp.tdiode\"\''\
      - dst_key: tegrastats.power_consumption.VDD_SYS_GPU.instant\
        src_key: '\'\"tegrastats.power.vdd_sys_gpu[current]\"\''\
      - dst_key: tegrastats.power_consumption.VDD_SYS_SOC.instant\
        src_key: '\'\"tegrastats.power.vdd_sys_soc[current]\"\''\
      - dst_key: tegrastats.power_consumption.VDD_IN.instant\
        src_key: '\'\"tegrastats.power.vdd_in[current]\"\''\
      - dst_key: tegrastats.power_consumption.VDD_SYS_CPU.instant\
        src_key: '\'\"tegrastats.power.vdd_sys_cpu[current]\"\''\
      - dst_key: tegrastats.power_consumption.VDD_SYS_DDR.instant\
        src_key: '\'\"tegrastats.power.vdd_sys_ddr[current]\"\''\
$(DC_JSON_CONDITIONAL_AGGREGATE_FILTER_CONVERTER_EXTENSION)/' ${D}${sysconfdir}/dc_conf/zabbix_inventory.yml
}