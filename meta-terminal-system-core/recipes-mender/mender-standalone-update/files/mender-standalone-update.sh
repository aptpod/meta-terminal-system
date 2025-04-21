#!/bin/bash
set -e

FILE=$1
MENDER_REBOOT_EXIT_CODE=4
MENDER_COMMIT_NO_UPDATE_EXIT_CODE=2
EXIT_CODE=0
IS_MENDER_CLIENT_ACTIVE=
STANDALONE_UPDATE_FORCE_COMMIT_FLAG="/tmp/.mender-standalone-update-force-commit-flag"

usage() {
    cat <<EOF
DESCRIPTION:
    install mender artifact.
USAGE:
    $(basename "${BASH_SOURCE[0]}") mender_artifact
EXIT CODE:
    0  success
    4  success(manual reboot is required)

EOF
    exit 0
}

stop_mender_client() {
    case "$(systemctl is-active mender-updated.service 2>/dev/null || true)" in
    active)
        echo "stop mender-updated.service"
        systemctl stop mender-updated.service
        IS_MENDER_CLIENT_ACTIVE=true
        ;;
    *)
        IS_MENDER_CLIENT_ACTIVE=false
        ;;
    esac
}

restart_mender_client() {
    if "${IS_MENDER_CLIENT_ACTIVE}"; then
        echo "restart mender-updated.service"
        systemctl start mender-updated.service
    fi
}

check() {
    if [ "$EUID" -ne 0 ]; then
        echo "Please run as root"
        exit 1
    fi

    if ! [ -f "$FILE" ]; then
        echo "$FILE is not found"
        exit 1
    fi
}

install() {
    local ret
    local tmplog=$(mktemp)

    stop_mender_client

    echo "install $FILE"
    ret=0
    mender-update install --reboot-exit-code "$FILE" || ret=$?

    # If reboot is required, set exit code 4
    if [ $ret -eq $MENDER_REBOOT_EXIT_CODE ]; then
        EXIT_CODE=$MENDER_REBOOT_EXIT_CODE
    elif [ $ret -ne 0 ]; then
        restart_mender_client
        exit $ret
    fi

    echo "commit $FILE"
    ret=0
    touch "$STANDALONE_UPDATE_FORCE_COMMIT_FLAG" && sync
    mender-update commit > $tmplog 2>&1 || ret=$?
    rm -f "$STANDALONE_UPDATE_FORCE_COMMIT_FLAG"

    # Suppress error logging if no updates
    if [ $ret -ne $MENDER_COMMIT_NO_UPDATE_EXIT_CODE ];then
        cat $tmplog && rm -f $tmplog
    fi

    # check commit error
    if [ $ret -ne 0 ] && [ $ret -ne $MENDER_COMMIT_NO_UPDATE_EXIT_CODE ]; then
        restart_mender_client
        exit $ret
    fi

    restart_mender_client
}

if [ -z "$FILE" ]; then
    usage
fi

check
install

echo "$FILE has been successfully installed"
exit $EXIT_CODE
