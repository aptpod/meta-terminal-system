FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

# The fix is in linux 5.15.209
SRC_URI:append = " \
    file://0001-CVE-2026-64125-net-bcmgenet-keep-RBUF-EEE-PM-disabled.patch \
    file://0001-CVE-2026-53088-bcmgenet-fix-txcb-rewind.patch \
"

# The fix is in linux 5.15.221; 5.15.92 takes the 5.10.270 backport because the
# 5.15 one also patches smc_tcp_syn_recv_sock, which 5.15.92 does not have
SRC_URI:append = " \
    file://0001-CVE-2026-43198-tcp-fix-potential-race-in-tcp_v6_syn_recv_sock.patch \
"

# The fix is in linux 5.15.143
SRC_URI:append = " \
    file://0001-CVE-2023-52881-tcp-do-not-accept-ACK-of-bytes-we-never-sent.patch \
"
