#!/bin/bash

SCRIPT_NAME=$(basename $0)
TIMEOUT_SEC=10

# parameter
CONTROL_MAP_PRIORITY="10"
CONTROL_MAP_ID="67fa8aba-649e-467d-931e-be747bc1bfd9"

# action
CONTROL_MAP_ACTION_CONTINUE="continue"
CONTROL_MAP_ACTION_FORCE_CONTINUE="force_continue"
CONTROL_MAP_ACTION_PAUSE="pause"
CONTROL_MAP_ACTION_FAIL="fail"
CONTROL_MAP_ACTION_DEFAULT="$CONTROL_MAP_ACTION_CONTINUE"

# control map
CONTROL_MAP_DEFAULT="{\
    \"priority\": $CONTROL_MAP_PRIORITY,\
    \"states\": { \
        \"ArtifactInstall_Enter\": { \
            \"action\": \"$CONTROL_MAP_ACTION_DEFAULT\"
        }, \
        \"ArtifactReboot_Enter\": { \
            \"action\": \"$CONTROL_MAP_ACTION_DEFAULT\" \
        }, \
        \"ArtifactCommit_Enter\": { \
            \"action\": \"$CONTROL_MAP_ACTION_DEFAULT\" \
        } \
    }, \
    \"id\": \"$CONTROL_MAP_ID\" \
}"
CONTROL_MAP_FORCE_CONTINUE="{\
    \"priority\": $CONTROL_MAP_PRIORITY,\
    \"states\": { \
        \"ArtifactInstall_Enter\": { \
            \"action\": \"$CONTROL_MAP_ACTION_FORCE_CONTINUE\"
        }, \
        \"ArtifactReboot_Enter\": { \
            \"action\": \"$CONTROL_MAP_ACTION_FORCE_CONTINUE\" \
        }, \
        \"ArtifactCommit_Enter\": { \
            \"action\": \"$CONTROL_MAP_ACTION_FORCE_CONTINUE\" \
        } \
    }, \
    \"id\": \"$CONTROL_MAP_ID\" \
}"

help() {
    cat <<EOF
Usage:
  $SCRIPT_NAME [OPTIONS]

Description:
  Update Mender control map.

Options:
  clear             Clear control map.
  force_continue    Update control map to force_continue.
EOF
    exit 1
}

check_mender_client_is_active() {
    is_active="$(systemctl is-active mender-client.service 2>/dev/null || true)"
    if [ "${is_active}" != "active" ]; then
        echo "Error: mender-client is not running"
        exit 1
    fi
}

wait_until_enabled_mender_update_manager() {
    for ((c = 1; c <= $TIMEOUT_SEC; c++)); do
        busctl introspect io.mender.UpdateManager /io/mender/UpdateManager >/dev/null 2>&1
        if [ $? -eq 0 ]; then
            return
        fi
        echo "Failed to introspect service io.mender.UpdateManager, retry."
        sleep 1
    done

    echo "Error: mender-client is not running"
    exit 1
}

update_control_map() {
    check_mender_client_is_active
    wait_until_enabled_mender_update_manager

    echo "Update control map = $(echo $CONTROL_MAP | jq -c .)"
    dbus-send --print-reply --system --dest=io.mender.UpdateManager /io/mender/UpdateManager io.mender.Update1.SetUpdateControlMap string:"${CONTROL_MAP}" >/dev/null 2>&1
}

case "$1" in
"clear")
    CONTROL_MAP=$CONTROL_MAP_DEFAULT
    update_control_map
    ;;
"force_continue")
    CONTROL_MAP=$CONTROL_MAP_FORCE_CONTINUE
    update_control_map
    ;;
*)
    help
    ;;
esac
