#!/usr/bin/env bash
set -e

echo '[
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=PCM"],
    "options": ["pcm"],
    "default": "pcm"
  },
  {
    "preconditions": ["DC_OUTPUT_DATA_TYPE=Opus RTP Packet"],
    "options": ["opus_rtp_packet"],
    "default": "opus_rtp_packet"
  }
]' | jq -c
