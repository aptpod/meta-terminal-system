# Enable arm_boost (Raspberry Pi 4 Only)
# Enable camera_auto_detect for Raspberry Pi Camera Module V2/V3
RPI_EXTRA_CONFIG:append:raspberrypi4-64 = "\n\
arm_boost=1\n\
camera_auto_detect=1\n\
"
