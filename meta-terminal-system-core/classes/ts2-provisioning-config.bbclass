populate_live:append() {
    if echo "${IMAGE_FSTYPES}" | grep -qw "hddimg"; then
        install -m 0644 ${DEPLOY_DIR_IMAGE}/ts2-provisioning-config-commit/ts2-config.txt ${HDDDIR}/ts2-config.txt
    fi
}

IMAGE_INSTALL:append = " ts2-provisioning-config-commit"
