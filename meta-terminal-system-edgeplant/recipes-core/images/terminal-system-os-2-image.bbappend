# Remove packagegroup-base-extended for compatibility with existing images
IMAGE_INSTALL:remove:jasmine = "packagegroup-base-extended"

# wlan
TERMINAL_IMAGE_EXTRA_INSTALL:append:jasmine = " kernel-modules-rtl8821au linux-firmware-rtl8188"

# exFAT
TERMINAL_IMAGE_EXTRA_INSTALL:append:jasmine = " fuse-exfat exfat-utils"

# volume save
TERMINAL_IMAGE_EXTRA_INSTALL:append:jasmine = " alsa-state"

# ssd initialize
TERMINAL_IMAGE_EXTRA_INSTALL:append:jasmine = " gptfdisk e2fsprogs"
