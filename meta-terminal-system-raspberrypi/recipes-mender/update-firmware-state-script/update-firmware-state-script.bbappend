# FIXME: WORKAROUND
# Revert the following commit due to a failure in updating the OS on Raspberry Pi 4.
# https://github.com/mendersoftware/meta-mender-community/pull/395

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"
