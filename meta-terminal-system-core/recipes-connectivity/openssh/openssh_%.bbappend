FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
SRC_URI += " \
             file://0001-fix-do-not-show-SSH_VERSION.patch \
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