#!/bin/bash

DEVICE_NAME=$1

if [ -z "$DEVICE_NAME" ]; then
  echo "Usage: $0 <device_name>"
  exit 1
fi

CCMINER_FILE="ccminer-v3.8.3c-oink_ARM"
CCMINER_URL="https://github.com/Oink70/ccminer-verus/releases/download/v3.8.3a-CPU/$CCMINER_FILE"

sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install ca-certificates libcurl4-openssl-dev libjansson-dev libomp-dev screen -y

echo "Installing libssl1.1"

curl -L -O http://ports.ubuntu.com/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_arm64.deb
sudo dpkg -i libssl1.1_1.1.0g-2ubuntu4_arm64.deb
rm libssl1.1_1.1.0g-2ubuntu4_arm64.deb

echo "Downloading ccminer"
curl -L -O $CCMINER_URL
mv $CCMINER_FILE ccminer
chmod +x ccminer

CPU_CORES=$(nproc --all)

cat << EOF > config.json
{
    "pools": [
        {
            "name": "pool.verus.io",
            "url": "stratum+tcp://pool.verus.io:9998",
            "timeout": 150,
            "disabled": 0
        },
        {
            "name": "verus.farm (Quipacorn)",
            "url": "stratum+tcp://verus.farm:9999",
            "timeout": 60,
            "time-limit": 600,
            "disabled": 0
        }
    ],
    "user": "RPtB89iNfnH9eiRtMJgpURce2daZja3F59.$DEVICE_NAME",
    "algo": "verus",
    "threads": $CPU_CORES,
    "cpu-priority": 1,
    "retry-pause": 5,
    "api-allow": "192.168.0.0/16",
    "api-bind": "0.0.0.0:4068"
}
EOF

cat << EOF > start.sh
#!/bin/sh
#exit existing screens with the name CCminer
screen -S CCminer -X quit 1>/dev/null 2>&1
#wipe any existing (dead) screens)
screen -wipe 1>/dev/null 2>&1
#create new disconnected session CCminer
screen -dmS CCminer 1>/dev/null 2>&1
#run the miner
screen -S CCminer -X stuff "~/ccminer -c ~/config.json\n" 1>/dev/null 2>&1
printf '\nMining started.\n'
printf '===============\n'
printf '\nManual:\n'
printf 'start: ~/start.sh\n'
printf 'stop: screen -X -S CCminer quit\n'
printf '\nmonitor mining: screen -x CCminer\n'
printf "exit monitor: 'CTRL-a' followed by 'd'\n\n"
EOF
chmod +x start.sh

echo "All done"
