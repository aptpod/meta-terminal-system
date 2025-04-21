FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:jasmine = " \
           file://default/intdash/agent.yaml.append \
           file://diagnostic-monitors/diskusage_media_ssd.yml \
           file://diagnostic-monitors/forced_power_off.yml \
           file://diagnostic-monitors/unexpected_power_interruption.yml \
           file://docker-compose/measurement/services/Audio_(Onboard).yml \
           file://docker-compose/measurement/services/GPS.yml \
"

do_install:append:jasmine() {
    sed -i \
        -e 's:@DEFAULT_GPS_DEVICE_PATH@:${DEFAULT_GPS_DEVICE_PATH}:' \
        -e 's:@DEFAULT_GPS_UBX_BAUDRATE@:${DEFAULT_GPS_UBX_BAUDRATE}:' \
        ${D}${sysconfdir}/core/docker-compose/measurement/services/GPS.yml
}