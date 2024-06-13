#!/bin/bash -e

# define device spedific variables
DEVICE_SPECIFIC_HELP="\
    --vcgencmd            Print vcgencmd\
"
DEVICE_SPECIFIC_LONG_OPTS+=",vcgencmd"

function array_to_json {
    declare -n array=$1
    printf '{'
    local first=true
    for key in "${!array[@]}"; do
        if [ "$first" = true ]; then
            first=false
        else
            printf ','
        fi
        printf '"%s":"%s"' "$key" "${array[$key]}"
    done
    printf '}'
}

function collect_content_device_specific_vcgencmd() {
    local throttled="$(vcgencmd get_throttled | sed -n 's/^throttled=\(.*\)/\1/p')"
    local under_voltage_now=false
    local under_voltage_occurred=false
    local arm_frequency_capped_now=false
    local arm_frequency_capped_occurred=false
    local currently_throttled_now=false
    local currently_throttled_occurred=false
    local soft_temperature_limit_now=false
    local soft_temperature_limit_occurred=false
    if [[ $((${throttled})) -ne 0 ]]; then
        if [ $((${throttled} & 0x00001)) -ne 0 ]; then
            under_voltage_now=true
        fi
        if [ $((${throttled} & 0x10000)) -ne 0 ]; then
            under_voltage_occurred=true
        fi

        if [ $((${throttled} & 0x00002)) -ne 0 ]; then
            arm_frequency_capped_now=true
        fi
        if [ $((${throttled} & 0x20000)) -ne 0 ]; then
            arm_frequency_capped_occurred=true
        fi

        if [ $((${throttled} & 0x00004)) -ne 0 ]; then
            currently_throttled_now=true
        fi
        if [ $((${throttled} & 0x40000)) -ne 0 ]; then
            currently_throttled_occurred=true
        fi

        if [ $((${throttled} & 0x00008)) -ne 0 ]; then
            soft_temperature_limit_now=true
        fi
        if [ $((${throttled} & 0x80000)) -ne 0 ]; then
            soft_temperature_limit_occurred=true
        fi
    fi

    local temp="$(vcgencmd measure_temp | sed -n 's/^temp=\([0-9.]*\).*/\1/p')"

    declare -A freqs
    for clock in arm core h264 isp v3d uart pwm emmc pixel vec hdmi dpi; do
        freqs[$clock]="$(vcgencmd measure_clock $clock | sed -n 's/^frequency(.*)=\([0-9.]*\)/\1/p')"
    done

    declare -A volts
    for volt in core sdram_c sdram_i sdram_p; do
        volts[$volt]="$(vcgencmd measure_volts $volt | sed -n 's/^volt=\([0-9.]*\).*/\1/p')"
    done

    declare -A configs
    local get_config="$(vcgencmd get_config int && vcgencmd get_config str)"
    for config in $(echo "$get_config" | awk -F'=' '{print $1}'); do
        configs[$config]="$(echo "$get_config" | grep "${config}=" | awk -F'=' '{print $2}')"
    done

    declare -A mems
    for mem in arm gpu; do
        mems[$mem]="$(vcgencmd get_mem $mem | awk -F'=' '{print $2}')"
    done

    declare -A codecs
    for codec in AGIF FLAC H263 H264 MJPA MJPB MJPG MPG2 MPG4 MVC0 PCM THRA VORB VP6 VP8 WMV9 WVC1; do
        codecs[$codec]="$(vcgencmd codec_enabled $codec | awk -F'=' '{print $2}')"
    done

    local vcgencmd_json="{ \
        \"throttled\": { \
            \"now\": { \
                \"under_voltage\": $under_voltage_now, \
                \"arm_frequency_capped\": $arm_frequency_capped_now, \
                \"currently_throttled\": $currently_throttled_now, \
                \"soft_temperature_limit\": $soft_temperature_limit_now \
            }, \
            \"occurred\": { \
                \"under_voltage\": $under_voltage_occurred, \
                \"arm_frequency_capped\": $arm_frequency_capped_occurred, \
                \"currently_throttled\": $currently_throttled_occurred, \
                \"soft_temperature_limit\": $soft_temperature_limit_occurred \
            } \
        }, \
        \"temp\": \"$temp\", \
        \"freq\": $(array_to_json freqs), \
        \"volt\": $(array_to_json volts), \
        \"config\": $(array_to_json configs), \
        \"mem\": $(array_to_json mems), \
        \"codec\": $(array_to_json codecs) \
    }"

    content_device_specific_vcgencmd="$(echo $vcgencmd_json | jq '{"vcgencmd": .}')"
}

function collect_content_device_specific() {
    collect_content_device_specific_vcgencmd

    content_device_specific="$(echo \
        $content_device_specific_vcgencmd |
        jq -s add)"
}
