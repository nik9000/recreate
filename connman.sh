#!/bin/bash

set -e
set +o pipefail

sudo dnf install -y connman wpa_supplicant bluez openvpn
sudo systemctl stop NetworkManager.service || true
sudo systemctl disable NetworkManager.service || true
sudo systemctl enable wpa_supplicant
sudo systemctl start wpa_supplicant
sudo mkdir -p /etc/connman
sudo tee /etc/connman/main.conf <<CONF
[General]
NetworkInterfaceBlacklist=vmnet,vboxnet,virbr,ifb,docker,veth,eth,wlan
CONF
sudo systemctl enable connman
sudo systemctl start connman
sudo dnf remove -y NetworkManager || true


connmanctl enable wifi
connmanctl scan wifi
connmanctl services
echo "Run connmanctl - agent on - connect <network>"

