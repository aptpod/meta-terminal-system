#!/bin/bash

readonly ARCHIVE_DIR="/var/lib/docker-archive-load"
readonly PREINSTALL_LIST="${ARCHIVE_DIR}/.preinstall-images"
readonly LOADED_FLAG="/data/.docker_archive_preinstall_loaded"

PREINSTALL_IMAGES=()

show_help() {
    cat <<EOF
Usage: docker-archive-load.sh [ARCHIVE_FILE]

Load Docker image archives.

Options:
  -h, --help    Show this help message

Examples:
  1. Small images (fits in tmpfs):
     cp image.tar.gz ${ARCHIVE_DIR}/
     docker-archive-load.sh

  2. Large images (use persistent storage to avoid tmpfs):
     docker-archive-load.sh \$CUSTOM_CONTENTS_DIR/path/to/image.tar.gz

Note: ${ARCHIVE_DIR} is on tmpfs (volatile memory).
EOF
}

is_loaded() {
    local filename="$1"
    if [ -f "${LOADED_FLAG}" ]; then
        grep -Fxq "${filename}" "${LOADED_FLAG}"
    else
        return 1
    fi
}

is_preinstall() {
    local filename="$1"
    for img in "${PREINSTALL_IMAGES[@]}"; do
        if [ "${filename}" = "${img}" ]; then
            return 0
        fi
    done
    return 1
}

load_docker_image() {
    local archive="$1"
    echo "Loading ${archive}"
    cat "${archive}" | gzip -d | docker load
}

show_error_help() {
    echo ""
    echo "If tmpfs is insufficient for this image size,"
    echo "use the direct path method from persistent storage:"
    echo "  docker-archive-load.sh \$CUSTOM_CONTENTS_DIR/path/to/archive.tar.gz"
    echo ""
}

# Show help
if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

# Direct load from specified path
if [ -n "$1" ]; then
    if [ ! -f "$1" ]; then
        echo "Error: File not found: $1"
        exit 1
    fi
    if ! load_docker_image "$1"; then
        exit 1
    fi
    echo "Successfully loaded $1"
    exit 0
fi

# Load from archive directory
if [ -z "$(ls ${ARCHIVE_DIR}/*.tar.gz 2>/dev/null)" ]; then
    echo "No archives to load"
    exit 0
fi

# Load preinstall list
if [ -f "${PREINSTALL_LIST}" ]; then
    mapfile -t PREINSTALL_IMAGES < "${PREINSTALL_LIST}"
fi

for archive in "${ARCHIVE_DIR}"/*.tar.gz; do
    filename=$(basename "${archive}")

    # Skip already loaded preinstall images
    if is_preinstall "${filename}" && is_loaded "${filename}"; then
        echo "Skipping: ${filename} (already loaded)"
        continue
    fi

    # Load image
    if ! load_docker_image "${archive}"; then
        echo "Error loading ${archive}"
        show_error_help "${archive}"
        exit 1
    fi

    echo "Successfully loaded ${archive}"

    # Record or remove
    if is_preinstall "${filename}"; then
        echo "${filename}" >> "${LOADED_FLAG}"
        echo "Recorded: ${filename}"
    else
        rm -f "${archive}"
        echo "Removed: ${filename}"
    fi
done

echo "Docker archive load completed"
