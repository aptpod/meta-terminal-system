#!/usr/bin/env bash
set -e

echo '[
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=PCM"],
    "options": ["44100", "48000"],
    "default": "48000"
  },
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=Opus RTP Packet"],
    "options": ["48000"],
    "default": "48000"
  }
]' | jq -c
