
# Since we need packages equivalent to NVIDIA's l4t-base container, we will add the packages missing from the original recipe.
SRC_SOC_DEBS += "\
    ${@l4t_deb_pkgname(d, 'multimedia-utils')};subdir=${BP}/full;name=multimedia-utils \
    ${@l4t_deb_pkgname(d, '3d-core')};subdir=${BP}/full;name=3d-core \
    ${@l4t_deb_pkgname(d, 'core')};subdir=${BP}/full;name=core \
"

MULTIMEDIAUTILSUM = "013bb6e293abda453ff177e591b927269fdce2c2693447157f3ce40d5ce9ffae"
SRC_URI[multimedia-utils.sha256sum] = "${MULTIMEDIAUTILSUM}"

THREEDCORESUM = "1fa3a9d3af25bdb0c9c000419b19eb74996c768b15d11c8fff9a6165c8632b24"
SRC_URI[3d-core.sha256sum] = "${THREEDCORESUM}"

CORESUM = "7b81a016d6a0f283553b01516fa562c8c99c95bb87d88b680dcbc113e8bfa938"
SRC_URI[core.sha256sum] = "${CORESUM}"

# To run NVIDIA containers, we must map to the same installation path as the deb package.
# Therefore, install the libraries directly under /usr/lib/ so that they are mounted as /usr/lib/aarch64-linux-gnu/ inside the container.
do_install() {
    install -d ${D}/usr/lib
    cp -R --preserve=mode,links,timestamps ${S}/usr/lib/aarch64-linux-gnu/* ${D}/usr/lib/
    cp -R --preserve=mode,links,timestamps ${S}/full/usr/lib/aarch64-linux-gnu/* ${D}/usr/lib/
}

FILES_SOLIBSDEV = ""
FILES:${PN} = "${libdir}"

CONTAINER_CSV_FILES = "${libdir}/*.so*"
CONTAINER_CSV_FILES += " \
    ${libdir}/*.so* \
    ${libdir}/tegra-egl/*.so* \
    ${libdir}/weston/*.so* \
    ${libdir}/tegra/*.so* \
    ${libdir}/tegra/weston/*.so* \
    ${libdir}/gstreamer-1.0/*.so* \
    ${libdir}/libv4l/plugins/nv/*.so* \
"
CONTAINER_CSV_PKGNAME = "${CONTAINER_CSV_BASENAME}-container-csv"
