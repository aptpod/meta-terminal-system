#!/usr/bin/env bash
set -e

echo '[
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=PCM"],
    "options": ["S16LE", "S32LE", "F32LE"],
    "default": "S16LE"
  },
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=Opus RTP Packet"],
    "options": ["---"],
    "default": "---"
  }
]' | jq -c
