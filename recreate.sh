#!/bin/bash

set -e
set +o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

echo "Caching sudo privileges"
sudo echo "got 'em"

echo "Creating ~/Bin"
mkdir -p ~/Bin

echo "Hacking backlight"
cat <<__CONF | sudo tee /etc/X11/xorg.conf.d/10-backlight.conf
Section "Device"
    Identifier  "Card0"
    Driver      "intel"
    Option      "Backlight"  "intel_backlight"
EndSection
__CONF

echo "Creating multi-monitor script"
cat <<__BASH | tee ~/Bin/multi-monitor
#!/bin/bash

xrandr --output eDP1 --auto --output DP1 --auto --right-of eDP1
__BASH
chmod +x ~/Bin/multi-monitor

echo "Install a nice font"
sudo dnf install pcaro-hermit-fonts.noarch

echo "Install window manager"
sudo dnf install i3

echo "Install background manager"
sudo dnf install feh

echo "Setting up config"
cp $DIR/config/i3/config ~/.config/i3/config
cp $DIR/config/i3status/config ~/.config/i3status/config

echo "Install VirtualBox"
# Looks like this is in rpmfusion anyway
# wget -q https://www.virtualbox.org/download/oracle_vbox.asc -O- | sudo rpm --import -
# wget -q https://download.virtualbox.org/virtualbox/rpm/fedora/virtualbox.repo -O- | sudo tee /etc/yum.repos.d/virtualbox.repo
sudo dnv install VirtualBox
