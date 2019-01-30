#!/bin/bash

if [ ! -d ~/Bin/sig ]; then
    mkdir -p ~/Bin/sig
    openssl req -new -x509 -newkey rsa:2048 -keyout ~/Bin/sig/MOK.priv -outform DER -out ~/Bin/sig/MOK.der -nodes -days 36500 -subj "/CN=Akrog/"
    sudo mokutil --import ~/Bin/sig/MOK.der
    echo "Reboot to enroll the key"
fi
for mod in $(cat /usr/lib/modules-load.d/VirtualBox.conf); do
    sudo /usr/src/kernels/$(uname -r)/scripts/sign-file sha256 ~/Bin/sig/MOK.priv ~/Bin/sig/MOK.der $(modinfo -n $mod)
done
sudo  systemctl restart systemd-modules-load.service