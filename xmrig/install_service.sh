#!/bin/bash

VERSION=6.22.2
COINS=("vulkan" "dinasty"  "yadacoin" "monero")
WORKER_NAME=$(hostname)

if [ -n "$1" ]; then
  WORKER_NAME=$1
fi

ARCH=$(arc)
OS_CODE=$(lsb_release -c | awk '{print $2}')

XMRIG_PACKAGE="xmrig-$VERSION-$OS_CODE-$ARCH.tar.gz"

echo "Downloading Xmrig $VERSION for $OS_CODE ($ARCH)"
curl -L -O https://github.com/xmrig/xmrig/releases/download/v$VERSION/$XMRIG_PACKAGE
tar -xzf $XMRIG_PACKAGE
rm $XMRIG_PACKAGE
mv $XMRIG_PACKAGE/* .
rmdir $XMRIG_PACKAGE

echo "Downloading configs"
for COIN in "${COINS[@]}"; do
  echo "Downloading config for $COIN"
  curl -L -O https://raw.githubusercontent.com/stormaaja/miningtools/refs/heads/main/xmrig/config_$COIN.json
done

echo "Updating configs with worker name: $WORKER_NAME"
for config_file in config_*.json; do
  if [ -f "$config_file" ]; then
    echo "Updating $config_file with worker name: $WORKER_NAME"
    sed -i "s/{{WORKER_NAME}}/$WORKER_NAME/g" "$config_file"
  fi
done

echo "Setting default coin to ${COINS[0]}"
echo ${COINS[0]} > coin.txt

echo "Creating start script"
cat >start.sh <<EOL
#!/bin/bash

COIN=$(cat coin.txt)
if [ -z "$COIN" ]; then
  echo "No coin specified. Please set the coin in coin.txt."
  exit 1
fi

xmrig --config config_$COIN.json
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
echo "You can check the status with: sudo systemctl status xmrig_miner.service"
echo "To view logs: journalctl -u xmrig_miner.service"
echo "To view logs in real-time: journalctl -u xmrig_miner.service -f"
echo "To change the coin, edit coin.txt and restart the service: sudo systemctl restart xmrig_miner.service"

