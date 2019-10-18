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


header "Install VSCode"
sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
sudo dnf install -y code
code --help > /dev/null # run code to create the config files

header "Install Javas"
sudo dnf install -y jq
install_java() {
    VERSION=$1
    echo "Downloading java $VERSION"
    cd /tmp
    [ -f openjdk${VERSION}.tar.gz ] || curl $(curl -s https://jvm-catalog.elastic.co/jdk/latest_openjdk_${VERSION}_linux | jq -r .url) > openjdk${VERSION}.tar.gz
    tar -xf openjdk${VERSION}.tar.gz
    sudo rm -rf /usr/lib/jvm/java-${VERSION}
    sudo mv jdk-${VERSION}* /usr/lib/jvm/java-${VERSION}
    sudo chown -R root:root /usr/lib/jvm/java-${VERSION}
}
sudo dnf install -y java-1.8.0-openjdk-devel
install_java  9
install_java 10
install_java 11
install_java 12
cat <<__BASH | tee ~/.java_env
export JAVA8_HOME=/usr/lib/jvm/java-1.8.0
export JAVA9_HOME=/usr/lib/jvm/java-9
export JAVA10_HOME=/usr/lib/jvm/java-10
export JAVA11_HOME=/usr/lib/jvm/java-11
export JAVA12_HOME=/usr/lib/jvm/java-12
export JAVA_HOME=\$JAVA12_HOME
__BASH
append ~/.bashrc "source ~/.java_env"

header "Install Slack"
rpm -q slack || sudo dnf install -y https://downloads.slack-edge.com/linux_releases/slack-3.4.2-0.1.fc21.x86_64.rpm

header "Install Docker"
sudo dnf -y install dnf-plugins-core
sudo dnf config-manager \
    --add-repo \
    https://download.docker.com/linux/fedora/docker-ce.repo
sudo dnf config-manager --set-enabled docker-ce-test
sudo dnf install -y docker-ce docker-ce-cli containerd.io
sudo systemctl start docker
sudo systemctl enable docker

header "Place Pictures"
cp -r $DIR/Pictures/* ~/Pictures

## Make sure these are near the end so they can overwrite installs
header "Setting up config"
cp $DIR/config/vscode/settings.json ~/.config/Code/User/settings.json
sudo tee /etc/sysctl.d/max_user_watches.conf << __CONF
fs.inotify.max_user_watches=524288
__CONF
append ~/.bashrc "export PATH=\$PATH:~/Bin"
