#!/bin/bash

echo "Setting up MoneroOcean XMRig miner on Ubuntu 22.04"

echo "Checking if installation exists"
if [ -d /root/moneroocean ]; then
    echo "XMRig is already installed. All is good."
    exit 0
fi

echo "Updating system"
apt-get update

echo "Installing tools and dependencies"
apt-get install -y curl bc vim less msr-tools

echo "Setting up huge pages"
echo vm.nr_hugepages=1280 >> /etc/sysctl.conf

echo "Downloading and setting up miner"
curl -s -L https://raw.githubusercontent.com/MoneroOcean/xmrig_setup/master/setup_moneroocean_miner.sh | bash -s $1