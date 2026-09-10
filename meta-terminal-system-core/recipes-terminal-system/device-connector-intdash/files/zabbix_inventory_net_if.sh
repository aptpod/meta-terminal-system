#!/bin/bash
set -e -o pipefail

state_file=/var/run/zabbix/ts2.net.if.json
tmp_file="$state_file.$$.tmp"
trap 'rm -f "$tmp_file"' EXIT

interfaces=""
for sysfs_path in /sys/class/net/*; do
  # Only interfaces backed by real hardware have a device link, so this excludes
  # the virtual ones.
  if [ -e "$sysfs_path/device" ]; then
    interfaces+="${sysfs_path##*/}"$'\n'
  fi
done

# /proc/uptime is CLOCK_BOOTTIME, so an NTP or GPS step does not skew the rate.
read -r uptime _ 2>/dev/null < /proc/uptime || uptime=0

if [ -r "$state_file" ]; then
  prev_state_args=(--rawfile previous_state "$state_file")
else
  prev_state_args=(--arg previous_state "")
fi

# jq emits the inventory on the first line and the sample kept for the next
# invocation on the second one.
# Zabbix agent2 merges the command stderr into the item value, so anything the
# pipeline writes there would corrupt the JSON: discard it.
output=$(ip -s -j link show 2>/dev/null | jq -c \
  --arg interfaces "$interfaces" \
  --argjson now "$uptime" \
  "${prev_state_args[@]}" \
  '
  def num(f): (try f catch null) | if type == "number" then . else null end;

  def bps($current; $previous; $elapsed):
    if $previous == null or $elapsed == null or $elapsed <= 0 then 0
    elif $current <= $previous then 0
    else ($current - $previous) * 8 / $elapsed
    end;

  (($previous_state | try fromjson catch null) | if type == "object" then . else {} end) as $prev
  | ($interfaces | split("\n") | map(select(length > 0))) as $physical
  | [ .[] | select(.ifname | IN($physical[])) ] as $links
  | ($links | map({ (.ifname): { ts: $now, rx: (num(.stats64.rx.bytes) // 0), tx: (num(.stats64.tx.bytes) // 0) } }) | add // {}) as $state
  | ($links | map(
      ($prev[.ifname] | if type == "object" then . else null end) as $p
      | (num($p.ts) | if . == null then null else $now - . end) as $elapsed
      | (num(.stats64.rx.bytes) // 0) as $rx
      | (num(.stats64.tx.bytes) // 0) as $tx
      | { (.ifname): { stats64: {
            tx: { bytes: $tx, bps: bps($tx; num($p.tx); $elapsed) },
            rx: { bytes: $rx, bps: bps($rx; num($p.rx); $elapsed) }
          } } }
    ) | add // {}) as $inventory
  | $inventory, $state
  ' 2>/dev/null) || { rc=$?; output=""; }

inventory=${output%%$'\n'*}
state=${output#*$'\n'}
if [ "$state" = "$output" ]; then
  logger -t ts2.net.if "failed to collect link statistics (rc=${rc:-0})" 2>/dev/null || true
  echo "{}"
  exit 0
fi

echo "$inventory"

# zabbix-agent2.service creates the directory (RuntimeDirectory=zabbix), so no mkdir
# here. While the file cannot be written, bps is averaged since the last stored
# sample, or stays 0 if none ever was; keep emitting rather than dropping the item.
if { echo "$state" > "$tmp_file"; } 2>/dev/null; then
  mv -f "$tmp_file" "$state_file" 2>/dev/null || true
fi
