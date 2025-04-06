#!/bin/bash

if [ -z "$1" ]; then
  echo "Usage: $0 <worker_name>"
  exit 1
fi

WORKER_NAME=$1

# Go through config_*.json files and update the worker name by replacing {{WORKER_NAME}} with the actual name
for config_file in config_*.json; do
  if [ -f "$config_file" ]; then
    echo "Updating $config_file with worker name: $WORKER_NAME"
    sed -i "s/{{WORKER_NAME}}/$WORKER_NAME/g" "$config_file"
  fi
done
