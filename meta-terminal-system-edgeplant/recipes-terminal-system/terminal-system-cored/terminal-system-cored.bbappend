FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:jasmine = " \
           file://docker-compose/measurement/services/Audio_(Onboard).yml \
           file://docker-compose/measurement/services/GPS.yml \
"
