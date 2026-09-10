# The upstream /etc/profile derives PATH from the value handed over by sshd or
# login. That value differs per Yocto generation and per login path, so assign
# instead of augmenting to keep the login PATH identical everywhere.
if [ "$(id -u)" -eq 0 ]; then
	PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
else
	PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
fi
export PATH
