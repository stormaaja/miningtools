#!/bin/bash

VERSION=6.22.2
COINS=("vulkan" "dinasty"  "yadacoin" "monero")
WORKER_NAME=$(hostname)

if [ -n "$1" ]; then
  WORKER_NAME=$1
fi

LINUX_SYSTEM_CODE=$(lsb_release -c | awk '{print $2}')
if [ -n "$2" ]; then
  LINUX_SYSTEM_CODE=$2
fi

function download_xmrig() {
    ARCH="x64"

    OS_CODE=$1

    XMRIG_BASE_FILE="xmrig-$VERSION-$OS_CODE-$ARCH"
    XMRIG_PACKAGE="$XMRIG_BASE_FILE.tar.gz"

    echo "Downloading Xmrig $VERSION for $OS_CODE ($ARCH) from https://github.com/xmrig/xmrig/releases/download/v$VERSION/$XMRIG_PACKAGE"
    curl -L -O https://github.com/xmrig/xmrig/releases/download/v$VERSION/$XMRIG_PACKAGE
    echo "Extracting file"
    tar -xzf $XMRIG_PACKAGE
    FOLDER_NAME="xmrig-$VERSION"
    if [ ! -d "$FOLDER_NAME" ]; then
        echo "Error: Extracting $XMRIG_PACKAGE failed."
        rm $XMRIG_PACKAGE
        return 1
    fi
    rm $XMRIG_PACKAGE
    mv $FOLDER_NAME/* .
    rmdir $FOLDER_NAME
    return 0
}

download_xmrig $LINUX_SYSTEM_CODE
if [ $? -ne 0 ]; then
    echo "Error: Downloading $XMRIG_PACKAGE failed."
    echo "Provide the correct OS code for your system as an argument. For common linux distribution, use 'linux-static'"
    exit 1
fi

echo "Downloading configs"
for COIN in "${COINS[@]}"; do
  echo "Downloading config for $COIN https://raw.githubusercontent.com/stormaaja/miningtools/refs/heads/main/xmrig/config_$COIN.json"
  curl -L -O https://raw.githubusercontent.com/stormaaja/miningtools/refs/heads/main/xmrig/config_$COIN.json
    if [ ! -f "config_$COIN.json" ]; then
        echo "Error: Downloading config_$COIN.json failed."
        exit 1
    fi
done

MINER_DIR=$(pwd)

echo "Updating configs with worker name: $WORKER_NAME"
for config_file in config_*.json; do
  if [ -f "$config_file" ]; then
    echo "Updating $config_file with worker name: $WORKER_NAME"
    sed -i "s/{{WORKER_NAME}}/$WORKER_NAME/g" "$config_file"
    sed -i "s/{{LOG_FOLDER}}/$MINER_DIR/g" "$config_file"
  fi
done

echo "Setting default coin to ${COINS[0]}"
echo ${COINS[0]} > coin.txt

echo "Creating start script"

cat >start.sh <<EOL
#!/bin/bash

if [ "\$1" == "--help" ]; then
  echo "You can check the status with: sudo systemctl status xmrig_miner.service"
  echo "To view logs: journalctl -u xmrig_miner.service"
  echo "To view logs in real-time: journalctl -u xmrig_miner.service -f"
  echo "To change the coin, edit coin.txt and restart the service: sudo systemctl restart xmrig_miner.service"
  exit 0
fi

COIN=$(cat $MINER_DIR/coin.txt)
if [ -z "\$COIN" ]; then
  echo "No coin specified. Please set the coin in coin.txt."
  exit 1
fi

$MINER_DIR/xmrig --config $MINER_DIR/config_\$COIN.json
EOL
chmod +x start.sh

echo "Installing service"

MINER_DIR=$(pwd)

cat >/tmp/xmrig_miner.service <<EOL
[Unit]
Description=Xmrig miner service

[Service]
ExecStart=$MINER_DIR/start.sh
Restart=always
Nice=10
CPUWeight=1

[Install]
WantedBy=multi-user.target
EOL
sudo mv /tmp/xmrig_miner.service /etc/systemd/system/xmrig_miner.service
sudo systemctl daemon-reload
sudo systemctl enable xmrig_miner.service
sudo systemctl start xmrig_miner.service
sudo systemctl status xmrig_miner.service

echo "Xmrig miner service installed and started."
./start.sh --help

