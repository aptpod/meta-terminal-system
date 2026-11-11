FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
# Remove each CVE-2026-* patch below once the openssh recipe in poky carries the
# same fix: delete both the SRC_URI entry and the file under files/. A leftover
# file shadows the poky patch of the same name via FILESEXTRAPATHS, and a leftover
# entry makes do_patch fail on the already applied hunks.
SRC_URI += " \
             file://0001-fix-do-not-show-SSH_VERSION.patch \
             file://CVE-2026-35414-CVE-2026-35387.patch \
             file://CVE-2026-60002.patch \
"

do_install:append() {
	# sshd settings
	sed -i \
		-e 's:^#\?\(PermitRootLogin\) \(yes\|no\):\1 no:' \
		-e 's:^#\?\(RSAAuthentication\) \(yes\|no\):\1 yes:' \
		-e 's:^#\?\(PubkeyAuthentication\) \(yes\|no\):\1 yes:' \
		-e 's:^#\?\(PasswordAuthentication\) \(yes\|no\):\1 no:' \
		-e 's:^#\?\(PermitEmptyPasswords\) \(yes\|no\):\1 no:' \
		-e "\$a\\AllowUsers admin maint@127.0.0.1" \
		${D}${sysconfdir}/ssh/sshd_config
}