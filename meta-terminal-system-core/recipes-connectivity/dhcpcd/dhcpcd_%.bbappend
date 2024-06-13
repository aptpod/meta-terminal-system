# Disable dhcpcd.service
# DNS name resolution does not work when dhcpcd.service is enabled.
# NetworkManager uses dhcpcd internally, so the service can be disabled.
SYSTEMD_AUTO_ENABLE:${PN} = "disable"
