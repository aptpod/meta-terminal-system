#!/bin/bash

SCRIPT_NAME=$(basename $0)
STATE_SCRIPT_CURRENT_STATE_FILE="/data/mender/state_script_current_state"
UPDATE_CONTROL_MAP_SCRIPT="/usr/bin/mender-device-api-update-controlmap.sh"
MENDER_SERVER_URL="$(cat /data/mender/mender.conf | jq -r '.ServerURL')"
MENDER_SERVER_URL="$(cat /etc/mender/mender.conf | jq -r ".ServerURL // \"${MENDER_SERVER_URL}\"")"
TIMEOUT_SEC=10

check_mender_server_connection() {
    if ! curl --head --max-time 4 --connect-timeout 2 --location --silent --fail $MENDER_SERVER_URL >/dev/null 2>&1; then
        echo "Error: unable to connect to mender server"
        exit 1
    fi
}

get_mender_client_state() {
    for ((c = 1; c <= $TIMEOUT_SEC; c++)); do
        MENDER_CLIENT_STATE=$(cat ${STATE_SCRIPT_CURRENT_STATE_FILE})
        if ! [[ $MENDER_CLIENT_STATE =~ Sync* ]]; then
            echo "mender client state = $MENDER_CLIENT_STATE"
            return
        fi
        check_mender_server_connection
        sleep 1
    done

    echo "Error: failed to get mender client state"
    exit 1
}

update_control_map() {
    $UPDATE_CONTROL_MAP_SCRIPT "force_continue"
    if [ $? -ne 0 ]; then
        echo "Error: Failed to update control map"
        exit 1
    fi
}

wait_mender_client_state() {
    local exp_state=$1
    echo "Waiting for state = $exp_state"
    for ((c = 1; c <= $TIMEOUT_SEC; c++)); do
        local state=$(cat ${STATE_SCRIPT_CURRENT_STATE_FILE})
        if [ "$state" = "$exp_state" ]; then
            return
        fi
        echo "current state = $state"
        sleep 1
    done

    echo "Error: failed to wait mender client state = $exp_state"
    exit 1
}

wait_until_completed_mender_update() {
    wait_mender_client_state "ArtifactInstall_Leave"
    echo "Rebooting..."
    exit 0
}

get_mender_client_state

if [ "$MENDER_CLIENT_STATE" = "ArtifactInstall_Leave" ]; then
    update_control_map
    wait_until_completed_mender_update
else
    echo "No artifacts Installed."
fi
