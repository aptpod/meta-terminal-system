#!/usr/bin/env bash
set -e

echo '[
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=PCM"],
    "options": ["---"],
    "default": "---"
  },
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=Opus RTP Packet"],
    "options": ["cbr","vbr","constrained-vbr"],
    "default": "constrained-vbr"
  }
]' | jq -c
