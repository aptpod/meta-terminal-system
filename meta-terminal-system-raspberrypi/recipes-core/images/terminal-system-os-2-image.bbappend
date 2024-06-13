# Provisioning settings
TERMINAL_IMAGE_EXTRA_INSTALL:append = " rpi-ts2-config"

# Debugging tools
TERMINAL_IMAGE_EXTRA_INSTALL:append = " raspi-gpio i2c-tools"

# Prevents time slip to 1970-01-01 on system startup for devices without RTC.
TERMINAL_IMAGE_EXTRA_INSTALL:append = " ${@bb.utils.contains('MACHINE_FEATURES', 'rtc', '', 'fake-hwclock', d)}"
