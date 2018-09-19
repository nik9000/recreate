#!/bin/bash

set -e
set +o pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

header() {
    printf "==================== %-30s ====================\n" "$1"
}

append() {
    FILE="$1"
    LINE="$2"
    grep -qF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
}

header "Caching sudo privileges"
sudo echo "got 'em"

header "Creating ~/Bin"
mkdir -p ~/Bin

header "Hacking backlight"
cat <<__CONF | sudo tee /etc/X11/xorg.conf.d/10-backlight.conf
Section "Device"
    Identifier  "Card0"
    Driver      "intel"
    Option      "Backlight"  "intel_backlight"
EndSection
__CONF

header "Creating multi-monitor script"
cat <<__BASH | tee ~/Bin/multi-monitor
#!/bin/bash

xrandr --output eDP1 --auto --output DP1 --auto --right-of eDP1
__BASH
chmod +x ~/Bin/multi-monitor

header "Add rpm fusion"
sudo dnf install -y https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

header "Update"
sudo dnf update -y

header "Install vim"
sudo dnf install -y vim
append ~/.bashrc "export EDITOR=vim"

header "Install a nice font"
sudo dnf install -y pcaro-hermit-fonts.noarch

header "Install window manager"
sudo dnf install -y i3 i3status i3lock xautolock

header "Install connman"
sudo dnf install -y connman

header "Install background manager"
sudo dnf install -y feh

header "Install VirtualBox"
sudo dnf install -y VirtualBox

header "Install VSCode"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code

header "Install Javas"
sudo dnf install -y java-1.8.0-openjdk-devel java-9-openjdk-devel java-10-openjdk-devel java-11-openjdk-devel
cat <<__BASH | tee ~/.java_env
export JAVA8_HOME=/usr/lib/jvm/java-1.8.0
export JAVA9_HOME=/usr/lib/jvm/java-9
export JAVA10_HOME=/usr/lib/jvm/java-10
export JAVA11_HOME=/usr/lib/jvm/java-11
export JAVA_HOME=\$JAVA10_HOME
__BASH
append ~/.bashrc "source ~/.java_env"

header "Install Slack"
rpm -q slack || sudo dnf install -y https://downloads.slack-edge.com/linux_releases/slack-3.3.1-0.1.fc21.x86_64.rpm

## Make sure these are near the end so they can overwrite installs
header "Setting up config"
mkdir -p ~/.config/i3
cp $DIR/config/i3/config ~/.config/i3/config
mkdir -p ~/.config/i3status
cp $DIR/config/i3status/config ~/.config/i3status/config
cp $DIR/config/vscode/settings.json ~/.config/Code/User/settings.json
cp $DIR/config/xresources/Xresources ~/.Xresources
git config --global user.name "Nik Everett"
git config --global user.email "nik9000@gmail.com"
sudo tee /etc/sysctl.d/max_user_watches.conf << __CONF
fs.inotify.max_user_watches=524288
__CONF


header "Code"
mkdir -p ~/Code/Elastic/Elasticsearch
pushd ~/Code/Elastic/Elasticsearch
ls | grep -qF elasticsearch || git clone git@github.com:nik9000/elasticsearch.git -o nik9000
cd elasticsearch
git remote add elastic git@github.com:elastic/elasticsearch.git || echo "skipping"
git remote add desktop manybubbles@desktop:/home/manybubbles/Workspaces/Elasticsearch/master/elasticsearch || echo "skipping"
popd

