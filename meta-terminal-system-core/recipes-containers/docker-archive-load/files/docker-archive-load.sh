#!/bin/bash
# This script is used by docker-archive-load.service, which loads docker image archive at boot.

ARCHIVE_DIR="/var/lib/docker-archive-load"

if [ -z "$(ls ${ARCHIVE_DIR})" ]; then
    echo "No docker archive to load"
    exit 0
fi

for archive in "${ARCHIVE_DIR}"/*.tar.gz; do
    echo "loading ${archive}"
    cat "${archive}" | gzip -d | docker load
    if [ $? -ne 0 ]; then
        echo "Error loading ${archive}"
    else
        echo "Successfully loaded ${archive}"
        rm -f ${archive}
    fi
done
