#!/bin/bash -e

BOOT_PART_DIR="@MENDER_BOOT_PART_MOUNT_LOCATION@"
TS2_CONFIG="${BOOT_PART_DIR}/ts2-config.txt"

DATA_INITIALIZED_FILE="/data/.ts2-config-initialized"
DATA_MENDER_CONF="/data/mender/mender.conf"
DATA_SERIAL="/data/serial_number"

function load_env() {
  # default env
  OPT_USE_MENDER="true"
  OPT_SERIAL_NUMBER="$(awk '/Serial/ {print $3}' /proc/cpuinfo)"

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
    mender_conf=$(echo "{\"ServerURL\":\"\",\"TenantToken\":\"\"}")
    mender_conf=$(jq ". * ${mender_conf}" ${DATA_MENDER_CONF})
    printf "%s" "${mender_conf}" >${DATA_MENDER_CONF}
  else
    echo "writing serial number \"${OPT_SERIAL_NUMBER}\" to data partition"
    echo "${OPT_SERIAL_NUMBER}" >${DATA_SERIAL}

    test -z "${OPT_MENDER_SERVER_URL}" || echo "writing mender server url \"${OPT_MENDER_SERVER_URL}\""
    test -z "${MENDER_TENANT_TOKEN}" || echo "writing mender server token \"$(echo ${MENDER_TENANT_TOKEN} | cut -c 1-47)...\""
    mender_conf=$(echo "{\"ServerURL\":\"${OPT_MENDER_SERVER_URL}\",\"TenantToken\":\"${MENDER_TENANT_TOKEN}\"}" | jq -c 'with_entries(select(.value != ""))')
    mender_conf=$(jq ". * ${mender_conf}" ${DATA_MENDER_CONF})
    printf "%s" "${mender_conf}" >${DATA_MENDER_CONF}
  fi

  echo "change api user 'admin' password"
  sed -i "s@^admin:.*@admin:${API_USER_PASS_ADMIN}@g" /etc/core/htpasswd
  echo "change api user 'user' password"
  sed -i "s@^user:.*@user:${API_USER_PASS_USER}@g" /etc/core/htpasswd

  usermod -p ${USER_PASS_ROOT} root
  usermod -p ${USER_PASS_ADMIN} admin
  usermod -p ${USER_PASS_MAINT} maint

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
  check_required_env MENDER_TENANT_TOKEN
fi
validate_env API_USER_PASS_ADMIN '^\$apr1\$'
validate_env API_USER_PASS_USER '^\$apr1\$'
validate_env USER_PASS_ROOT '^\$6\$'
validate_env USER_PASS_ADMIN '^\$6\$'
validate_env USER_PASS_MAINT '^\$6\$'
validate_env OPT_USE_MENDER '^(true|false)$'
validate_env OPT_SERIAL_NUMBER '^[0-9a-zA-Z_.-]*$'
validate_env OPT_MENDER_SERVER_URL '^https?://.*$'
validate_env MENDER_TENANT_TOKEN '^.+$'
commit_config
