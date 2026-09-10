#!/bin/bash -e

TS2_PROVISIONING_CONFIG_DIR="@TS2_PROVISIONING_CONFIG_DIR@"
TS2_CONFIG="${TS2_PROVISIONING_CONFIG_DIR}/ts2-config.txt"

DATA_INITIALIZED_FILE="/data/.ts2-config-initialized"
DATA_MENDER_CONF="/data/mender/mender.conf"
DATA_SERIAL="/data/serial_number"

SERIAL_NUMBER_REQUIRED="@SERIAL_NUMBER_REQUIRED@"

function load_env() {
  # default env
  OPT_USE_MENDER="true"
  @SERIAL_NUMBER@="@SERIAL_NUMBER_DEFAULT@"

  source ${TS2_CONFIG}
}

function check_required_env() {
  local var_name=$1
  local var_value="${!var_name}"
  if [ -z "${var_value}" ]; then
    echo "ERROR: Environment variable \"${var_name}\" is not set"
    exit 1
  fi
}

function validate_env() {
  local var_name=$1
  local regex=$2
  local var_value="${!var_name}"
  if [ ! -z "${var_value}" ]; then
    if [[ ! ${var_value} =~ ${regex} ]]; then
      echo "ERROR: Environment variable \"${var_name}\" must match regex ${regex}"
      exit 1
    fi
  fi
}

function commit_config() {
  if [ "${OPT_USE_MENDER}" = "false" ]; then
    if [ -n "${@SERIAL_NUMBER@}" ]; then
      echo "writing serial number \"${@SERIAL_NUMBER@}\" to data partition"
      echo "${@SERIAL_NUMBER@}" >${DATA_SERIAL}
    else
      echo "clear serial number"
      echo "" >${DATA_SERIAL}
    fi

    echo "clear mender server url and token"
    echo "[INFO] The default Mender server URL has been removed. When provisioning with Mender enabled using the same image, it is necessary to configure the Mender server URL."
    mender_conf=$(echo "{\"ServerURL\":\"\",\"TenantToken\":\"\"}")
    mender_conf=$(jq ". * ${mender_conf}" ${DATA_MENDER_CONF})
    printf "%s" "${mender_conf}" >${DATA_MENDER_CONF}
  else
    echo "writing serial number \"${@SERIAL_NUMBER@}\" to data partition"
    echo "${@SERIAL_NUMBER@}" >${DATA_SERIAL}

    test -z "${OPT_MENDER_SERVER_URL}" || echo "writing mender server url \"${OPT_MENDER_SERVER_URL}\""
    test -z "${MENDER_TENANT_TOKEN}" || echo "writing mender server token \"$(echo ${MENDER_TENANT_TOKEN} | cut -c 1-47)...\""
    mender_conf=$(echo "{\"ServerURL\":\"${OPT_MENDER_SERVER_URL}\",\"TenantToken\":\"${MENDER_TENANT_TOKEN}\"}" | jq -c 'with_entries(select(.value != ""))')
    mender_conf=$(jq ". * ${mender_conf}" ${DATA_MENDER_CONF})
    printf "%s" "${mender_conf}" >${DATA_MENDER_CONF}
  fi

  if [ -n "${@SERIAL_NUMBER@}" ]; then
    hostname="$(echo "${@SERIAL_NUMBER@}" | tr -d '_.')"
    hostname="$(echo "${hostname}" | sed 's/^-*//; s/-*$//')"
    hostname="$(echo "${hostname}" | cut -c1-63)"
  else
    hostname="terminal-system"
  fi
  echo "setting hostname \"${hostname}\""
  hostnamectl set-hostname "${hostname}"

  echo "change api user 'admin' password"
  sed -i "s@^admin:.*@admin:${API_USER_PASS_ADMIN}@g" /etc/core/htpasswd
  echo "change api user 'user' password"
  sed -i "s@^user:.*@user:${API_USER_PASS_USER}@g" /etc/core/htpasswd

  # Directly edit /etc/shadow instead of using usermod (which may not exist in read-only-rootfs)
  # Changes are persisted in /data/overlay/etc/shadow via overlayfs
  echo "change login password for root"
  sed -i "s|^root:[^:]*:|root:${USER_PASS_ROOT}:|" /etc/shadow
  echo "change login password for admin"
  sed -i "s|^admin:[^:]*:|admin:${USER_PASS_ADMIN}:|" /etc/shadow
  echo "change login password for maint"
  sed -i "s|^maint:[^:]*:|maint:${USER_PASS_MAINT}:|" /etc/shadow

  touch ${DATA_INITIALIZED_FILE}
  rm -f ${TS2_CONFIG}
}

if [ -e "${DATA_INITIALIZED_FILE}" ]; then
  echo "Already initialized."
  exit 1
fi

if [ ! -e "${TS2_CONFIG}" ]; then
  echo "ts2-config.txt not found."
  exit 1
fi

load_env
check_required_env API_USER_PASS_ADMIN
check_required_env API_USER_PASS_USER
check_required_env USER_PASS_ROOT
check_required_env USER_PASS_ADMIN
check_required_env USER_PASS_MAINT
if [ "${OPT_USE_MENDER}" = "true" ]; then
  if [ "${SERIAL_NUMBER_REQUIRED}" = "1" ]; then
    check_required_env @SERIAL_NUMBER@
  fi
  check_required_env MENDER_TENANT_TOKEN
fi
validate_env API_USER_PASS_ADMIN '^\$apr1\$'
validate_env API_USER_PASS_USER '^\$apr1\$'
validate_env USER_PASS_ROOT '^\$6\$'
validate_env USER_PASS_ADMIN '^\$6\$'
validate_env USER_PASS_MAINT '^\$6\$'
validate_env OPT_USE_MENDER '^(true|false)$'
validate_env @SERIAL_NUMBER@ '^[0-9a-zA-Z_.-]*$'
validate_env OPT_MENDER_SERVER_URL '^https?://.*$'
validate_env MENDER_TENANT_TOKEN '^.+$'
commit_config
