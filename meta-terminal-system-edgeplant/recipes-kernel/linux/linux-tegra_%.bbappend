FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append:jasmine = " \
    file://rtl8821au.cfg \
"

# Use the meta-terminal-system-core copy of the UVC payload size fix. Both patch the
# same hunk, so the meta-edgeplant patch has to be dropped.
SRC_URI:remove:jasmine = "file://0001-fix-uvc-max-payload-transfer-size.patch"
