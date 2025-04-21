#!/usr/bin/env bash
set -e

paths=$(find /dev -mindepth 2 -maxdepth 2 -path "/dev/input/js*" 2>/dev/null)
paths+=$'\n'$(find /dev -mindepth 3 -maxdepth 3 -path "/dev/input/by-*/*-joystick" ! -name "*-event-joystick" 2>/dev/null)

echo "$paths" | jq -R -s -c 'split("\n") | map(select(length > 0))'
