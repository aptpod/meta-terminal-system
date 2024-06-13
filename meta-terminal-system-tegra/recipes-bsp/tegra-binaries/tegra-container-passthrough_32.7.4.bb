L4T_DEB_COPYRIGHT_MD5 = "3d9212d4d5911fa3200298cd55ed6621"

L4T_DEB_TRANSLATED_BPN = "nvidia-l4t-multimedia"

require recipes-bsp/tegra-binaries/tegra-debian-libraries-common.inc

SRC_SOC_DEBS += " \
    nvidia-l4t-multimedia-utils_${PV}_arm64.deb;subdir=${BP};name=multimedia-utils \
    nvidia-l4t-camera_${PV}_arm64.deb;subdir=${BP};name=camera \
    nvidia-l4t-gstreamer_${PV}_arm64.deb;subdir=${BP};name=gstreamer \
    nvidia-l4t-wayland_${PV}_arm64.deb;subdir=${BP};name=wayland \
    nvidia-l4t-weston_${PV}_arm64.deb;subdir=${BP};name=weston \
    nvidia-l4t-libvulkan_${PV}_arm64.deb;subdir=${BP};name=libvulkan \
    nvidia-l4t-3d-core_${PV}_arm64.deb;subdir=${BP};name=3d-core \
    nvidia-l4t-core_${PV}_arm64.deb;subdir=${BP};name=core \
"

MAINSUM = "563784b9084fb4cecf36021bb8b6a4da014d27c8d4605ed830bd0fdcbbe16f09"
SRC_URI[multimedia-utils.sha256sum] = "ff227a2309781243b96e07eb5ad00b8d5c7cec11688025fdbfce20ab3a677900"
SRC_URI[camera.sha256sum] = "9c3a7f59f154909387706adc245cdf622fcd770e7c03d850a06723dac1da0f4c"
SRC_URI[gstreamer.sha256sum] = "185186f095899a96b2e10eab0753a34d02ea199302eda0fc57263a5ceb1ad9d7"
SRC_URI[wayland.sha256sum] = "a51e3d923b3255a76d25a2f0ce750b1f300a719008c67540bc9d3b3ecee3c1cc"
SRC_URI[weston.sha256sum] = "53c8c8fef98d2f9e6491fc3a4d301e012a1e6c91cb91e40d806571e46276663d"
SRC_URI[libvulkan.sha256sum] = "c80b2e1d3f4436617ca0629cbd8ea3c8d43be37fff2b5569e5a3ff452ede7bb6"
SRC_URI[3d-core.sha256sum] = "d65d21276997377e5fb744e25439d19c264cf1172c5a223a94a45e0d9964af79"
SRC_URI[core.sha256sum] = "8659b23489309907f3ac1f19b270306be37f6a4cc5ddac8cb35e96f5c3ae13bf"

do_install() {
    install -d ${D}/usr/lib
    cp -R --preserve=mode,links,timestamps ${S}/usr/lib/aarch64-linux-gnu/* ${D}/usr/lib/
}

CONTAINER_CSV_FILES += " \
    ${libdir}/tegra-egl/*.so* \
    ${libdir}/weston/*.so* \
    ${libdir}/tegra/*.so* \
    ${libdir}/tegra/weston/*.so* \
    ${libdir}/gstreamer-1.0/*.so* \
    ${libdir}/libv4l/plugins/nv/*.so* \
"

FILES_SOLIBSDEV = ""
EXCLUDE_FROM_SHLIBS = "1"
SKIP_FILEDEPS = "1"
FILES:${PN} = "${libdir}"
INSANE_SKIP:${PN} = "textrel"