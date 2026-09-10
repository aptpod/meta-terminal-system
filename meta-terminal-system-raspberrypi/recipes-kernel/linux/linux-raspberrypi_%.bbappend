FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# The fix is in linux 6.6.64; linux-raspberrypi is pinned to 6.6.63
SRC_URI:append = " \
    file://0001-CVE-2024-53206-tcp-fix-use-after-free-of-nreq-in-reqsk_timer_handler.patch \
"
# The fix is in linux 6.6.142
SRC_URI:append = " \
    file://0001-CVE-2026-64125-net-bcmgenet-keep-RBUF-EEE-PM-disabled.patch \
"
