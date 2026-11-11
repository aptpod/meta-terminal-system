FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:jasmine = " \
    file://rtl8821au.cfg \
"

# The fix is in linux 4.14.333; 4.9 has no fix of its own. Its follow-up
# f81e6c3fb063 is CVE-2026-98255, whose record leaves out kernels before 4.14
SRC_URI:append:jasmine = " \
    file://0001-CVE-2023-52881-tcp-do-not-accept-ACK-of-bytes-we-never-sent.patch \
"

# Use the meta-terminal-system-core copy of the UVC payload size fix, which covers
# more camera models than the meta-edgeplant one. Both patch the same hunk, so the
# meta-edgeplant patch has to be dropped.
SRC_URI:remove:jasmine = "file://0001-fix-uvc-max-payload-transfer-size.patch"
