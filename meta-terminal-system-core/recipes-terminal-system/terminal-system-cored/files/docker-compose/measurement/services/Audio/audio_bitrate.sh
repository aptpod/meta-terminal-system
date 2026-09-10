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
    "options": ["12000","16000","32000","64000","96000","128000","196000"],
    "default": "96000"
  }
]' | jq -c
