FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# The fix is in linux 6.6.142
SRC_URI:append = " \
    file://0001-CVE-2026-64125-net-bcmgenet-keep-RBUF-EEE-PM-disabled.patch \
"
