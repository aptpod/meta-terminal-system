#!/bin/sh
# All early-exit paths use exit 0: a missing modem must not block
# gpsd.service from starting (USE_MODEM_GNSS=yes machines may still
# have other GPS sources, and dev/QA configurations may omit modems).
set -u

TTYGPS=/dev/ttyGPS
WAIT_TIMEOUT=90

tty_ready=0
n=0
while [ "${n}" -lt "${WAIT_TIMEOUT}" ]; do
    if [ -e "${TTYGPS}" ]; then
        tty_ready=1
        break
    fi
    sleep 1
    n=$((n + 1))
done
if [ "${tty_ready}" -ne 1 ]; then
    echo "cellular-module-init-dispatch: ${TTYGPS} did not appear within ${WAIT_TIMEOUT}s" >&2
    exit 0
fi

# ModemManager.service reaching "Started" does not guarantee the modem
# has been probed. Wait until it appears in mmcli to avoid AT contention
# while MM is still probing.
modem_ready=0
n=0
while [ "${n}" -lt "${WAIT_TIMEOUT}" ]; do
    if mmcli -L 2>/dev/null | grep -q '/Modem/'; then
        modem_ready=1
        break
    fi
    sleep 1
    n=$((n + 1))
done
if [ "${modem_ready}" -ne 1 ]; then
    echo "cellular-module-init-dispatch: ModemManager did not expose a modem within ${WAIT_TIMEOUT}s" >&2
    exit 0
fi

MODULE_ID=$(udevadm info -q property "${TTYGPS}" 2>/dev/null | sed -n 's/^ID_CELLULAR_MODULE=//p' | head -n1)
if [ -z "${MODULE_ID}" ]; then
    echo "cellular-module-init-dispatch: ID_CELLULAR_MODULE not set on ${TTYGPS}" >&2
    exit 0
fi

INIT="/etc/cellular-module-init/${MODULE_ID}/init.sh"
if [ -x "${INIT}" ]; then
    echo "cellular-module-init-dispatch: ${MODULE_ID}, exec ${INIT}" >&2
    exec "${INIT}"
fi
echo "cellular-module-init-dispatch: ${MODULE_ID}, no init.sh" >&2
exit 0
