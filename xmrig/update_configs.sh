#!/bin/bash

COINS=("vulkan" "dinasty"  "yadacoin" "monero", "salvium")
WORKER_NAME=$(hostname)

if [ -n "$1" ]; then
  WORKER_NAME=$1
fi

MINER_DIR=$(pwd)

echo "Downloading configs"
for COIN in "${COINS[@]}"; do
  if [ -f "config_$COIN.json" ]; then
    echo "Config for $COIN already exists, skipping download."
    continue
  fi
  echo "Downloading config for $COIN https://raw.githubusercontent.com/stormaaja/miningtools/refs/heads/main/xmrig/config_$COIN.json"
  curl -L -O https://raw.githubusercontent.com/stormaaja/miningtools/refs/heads/main/xmrig/config_$COIN.json
    if [ ! -f "config_$COIN.json" ]; then
        echo "Error: Downloading config_$COIN.json failed."
        exit 1
    fi
done

echo "Updating configs with worker name: $WORKER_NAME"
for config_file in config_*.json; do
if [ -f "$config_file" ]; then
    echo "Updating $config_file with worker name: $WORKER_NAME"
    sed -i "s#{{WORKER_NAME}}#$WORKER_NAME#g" "$config_file"
    sed -i "s#{{LOG_FOLDER}}#$MINER_DIR#g" "$config_file"
  fi
done