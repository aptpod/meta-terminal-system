# docker support
TERMINAL_IMAGE_EXTRA_INSTALL:append = " nvidia-container-runtime"

# mount libraries from the l4t deb package with nvidia container runtime
TERMINAL_IMAGE_EXTRA_INSTALL:append = " tegra-container-passthrough"
## avoid Argus error
TERMINAL_IMAGE_EXTRA_INSTALL:append = " tegra-argus-daemon"
## mount /etc/enctune.conf
TERMINAL_IMAGE_EXTRA_INSTALL:append = " tegra-configs-omx-tegra"

# libraries and services used by nvidia containers
TERMINAL_IMAGE_EXTRA_INSTALL:append = " cuda-libraries tensorrt-plugins-prebuilt"
