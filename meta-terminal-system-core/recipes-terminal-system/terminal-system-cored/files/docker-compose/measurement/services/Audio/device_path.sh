#!/usr/bin/env bash
set -e

dc-utils alsa list | jq -c "[.cards[].by_path]"