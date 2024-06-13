#!/bin/bash -e

POWERMANAGE_LOCK_PATH="/var/lock/edgeplant_powermanage.lock"
POWERMANAGE_TIMEOUT=10

# define device spedific variables
DEVICE_SPECIFIC_HELP="\
    --tegrastats          Print tegrastats\
"
DEVICE_SPECIFIC_LONG_OPTS+=",tegrastats"

function edgeplant_powermanage_cmd() {
    local cmd="$1"
    flock --timeout $POWERMANAGE_TIMEOUT $POWERMANAGE_LOCK_PATH -c "/usr/bin/edgeplant-l4t/edgeplant_powermanage $cmd" || true
}

function collect_content_firmware_device_specific_powermanage() {
    local dump="$(edgeplant_powermanage_cmd dump)"
    local version="$(echo "$dump" | grep 'version: ' | sed -e 's/version: \(.*\)/\1/g')"
    content_firmware_device_specific_powermanage='{"powermanage": {"version": "'$version'", "dump": "'$dump'"}}'
}

function collect_content_firmware_device_specific() {
    collect_content_firmware_device_specific_powermanage

    content_firmware_device_specific="$(echo \
        $content_firmware_device_specific_powermanage |
        jq -c -s add)"
}

function collect_content_device_specific_tegrastats() {
    local tegrastats="$(timeout 0.5 tegrastats --interval 100 | head -n 1)"

    # usage & frequency
    local emc=$(echo $tegrastats | sed -n 's/^.*EMC_FREQ \([0-9]*\)%@\([0-9]*\).*$/\1 \2/p')
    read emc_usage emc_freq <<<$emc
    local gr3d=$(echo $tegrastats | sed -n 's/^.*GR3D_FREQ \([0-9]*\)%@\([0-9]*\).*$/\1 \2/p')
    read gr3d_usage gr3d_freq <<<$gr3d
    local vic=$(echo $tegrastats | sed -n 's/^.*VIC_FREQ \([0-9]*\)%@\([0-9]*\).*$/\1 \2/p')
    read vic_usage vic_freq <<<$vic

    # temperature
    local pll=$(echo $tegrastats | sed -n 's/^.*PLL@\([0-9.]*\)C.*$/\1/p')
    local mcpu=$(echo $tegrastats | sed -n 's/^.*MCPU@\([0-9.]*\)C.*$/\1/p')
    local pmic=$(echo $tegrastats | sed -n 's/^.*PMIC@\([0-9.]*\)C.*$/\1/p')
    local tboard=$(echo $tegrastats | sed -n 's/^.*Tboard@\([0-9.]*\)C.*$/\1/p')
    local gpu=$(echo $tegrastats | sed -n 's/^.*GPU@\([0-9.]*\)C.*$/\1/p')
    local bcpu=$(echo $tegrastats | sed -n 's/^.*BCPU@\([0-9.]*\)C.*$/\1/p')
    local thermal=$(echo $tegrastats | sed -n 's/^.*thermal@\([0-9.]*\)C.*$/\1/p')
    local tdiode=$(echo $tegrastats | sed -n 's/^.*Tdiode@\([0-9.]*\)C.*$/\1/p')

    # power_consumption
    local vdd_sys_gpu=$(echo $tegrastats | sed -n 's/^.*VDD_SYS_GPU \([0-9]*\)\/\([0-9]*\).*$/\1 \2/p')
    read vdd_sys_gpu_instant vdd_sys_gpu_average <<<$vdd_sys_gpu
    local vdd_sys_soc=$(echo $tegrastats | sed -n 's/^.*VDD_SYS_SOC \([0-9]*\)\/\([0-9]*\).*$/\1 \2/p')
    read vdd_sys_soc_instant vdd_sys_soc_average <<<$vdd_sys_soc
    local vdd_in=$(echo $tegrastats | sed -n 's/^.*VDD_IN \([0-9]*\)\/\([0-9]*\).*$/\1 \2/p')
    read vdd_in_instant vdd_in_average <<<$vdd_in
    local vdd_sys_cpu=$(echo $tegrastats | sed -n 's/^.*VDD_SYS_CPU \([0-9]*\)\/\([0-9]*\).*$/\1 \2/p')
    read vdd_sys_cpu_instant vdd_sys_cpu_average <<<$vdd_sys_cpu
    local vdd_sys_ddr=$(echo $tegrastats | sed -n 's/^.*VDD_SYS_DDR \([0-9]*\)\/\([0-9]*\).*$/\1 \2/p')
    read vdd_sys_ddr_instant vdd_sys_ddr_average <<<$vdd_sys_ddr

    local tegrastats_json="{ \
        \"emc\": {\"usage\": \"$emc_usage\", \"frequency\": \"$emc_freq\"}, \
        \"gpu\": {\"usage\": \"$gr3d_usage\", \"frequency\": \"$gr3d_freq\"}, \
        \"vic\": {\"usage\": \"$vic_usage\", \"frequency\": \"$vic_freq\"}, \
        \"temperature\": { \
            \"PLL\": \"$pll\", \
            \"MCPU\": \"$mcpu\", \
            \"PMIC\": \"$pmic\", \
            \"Tboard\": \"$tboard\", \
            \"GPU\": \"$gpu\", \
            \"BCPU\": \"$bcpu\", \
            \"thermal\": \"$thermal\", \
            \"Tdiode\": \"$tdiode\" \
        }, \
        \"power_consumption\": { \
            \"VDD_SYS_GPU\": {\"instant\": \"$vdd_sys_gpu_instant\", \"average\": \"$vdd_sys_gpu_average\"}, \
            \"VDD_SYS_SOC\": {\"instant\": \"$vdd_sys_soc_instant\", \"average\": \"$vdd_sys_soc_average\"}, \
            \"VDD_IN\": {\"instant\": \"$vdd_in_instant\", \"average\": \"$vdd_in_average\"}, \
            \"VDD_SYS_CPU\": {\"instant\": \"$vdd_sys_cpu_instant\", \"average\": \"$vdd_sys_cpu_average\"}, \
            \"VDD_SYS_DDR\": {\"instant\": \"$vdd_sys_ddr_instant\", \"average\": \"$vdd_sys_ddr_average\"} \
        } \
    }"

    content_device_specific_tegrastats="$(echo $tegrastats_json | jq '{"tegrastats": .}')"
}

function collect_content_device_specific() {
    collect_content_device_specific_tegrastats

    content_device_specific="$(echo \
        $content_device_specific_tegrastats |
        jq -s add)"
}
