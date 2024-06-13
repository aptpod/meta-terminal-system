FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " file://fragment_hwclock.cfg \
             file://fragment_runparts.cfg \
             file://fragment_init.cfg \
             file://fragment_ping.cfg \
           "
