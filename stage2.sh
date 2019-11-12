#!/bin/bash

set -xeo pipefail

append() {
  FILE="$1"
  LINE="$2"
  grep -qF -- "$LINE" "$FILE" || echo "$LINE" >> "$FILE"
}

install() {
  pacman -S --noconfirm --needed $@
}

install_aur() {
  sudo -u manybubbles bash <<BASH
    set -xeo pipefail
    mkdir -p Code/ArchUserRepository
    cd Code/ArchUserRepository
    if [ -e $1 ]; then
      cd $1
      git pull | grep 'Already up to date.' || rm $1*.pkg.tar.xz
    else
      git clone https://aur.archlinux.org/$1.git
      cd $1
    fi
    ls $1*.pkg.tar.xz || makepkg
BASH
  pacman -U --noconfirm $(pwd)/Code/ArchUserRepository/$1/$1*.pkg.tar.xz
}

append ~/.bashrc "export PATH=\$PATH:~/Bin"

echo Update everything we already have
pacman -Syu --noconfirm

echo Setup basics
install man base-devel git

echo Setup vim
install vim
append ~manybubbles/.bashrc "export EDITOR=vim"

echo Grab a nice font
install fontconfig xorg-font-utils
install_aur otf-hermit

echo Setup display manager
install lightdm lightdm-gtk-greeter accountsservice
systemctl enable lightdm

echo Setup i3
install xorg xorg-xinit i3-gaps i3blocks i3lock i3status xautolock feh xorg-xbacklight scrot rxvt-unicode dmenu alsa-utils notification-daemon libnotify dunst
sudo -u manybubbles bash <<BASH
  set -xeo pipefail
  mkdir -p ~/.config/i3
  cp config/i3/config ~/.config/i3/config
  mkdir -p ~/.config/i3status
  cp config/i3status/config ~/.config/i3status/config
  mkdir -p ~/.config/dunst
  cp config/dunst/dunstrc ~/.config/dunst/dunstrc
  cp config/xresources/$DPI/Xresources ~/.Xresources
BASH

echo Setup git
install git
sudo -u manybubbles bash <<BASH
  set -xeo pipefail
  git config --global user.name "Nik Everett"
  git config --global user.email "nik9000@gmail.com"
  git config --global alias.pr '!f() { git fetch elastic pull/$1/head:pr_$1; git checkout pr_$1; }; f'
BASH
install_aur bash-completion-git

echo Setup firefox
install firefox

echo Setup VSCode
install code
sudo -u manybubbles bash <<BASH
  set -xeo pipefail
  mkdir -p "$HOME/.config/Code - OSS/User"
  cp config/vscode/settings.json "$HOME/.config/Code - OSS/User/settings.json"
BASH
sudo tee /etc/sysctl.d/max_user_watches.conf << CONF
  fs.inotify.max_user_watches=524288
CONF


echo Setup slack
install libappindicator-gtk3 # https://aur.archlinux.org/packages/slack-desktop/#comment-714391
install libcurl-compat xdg-utils
install_aur slack-desktop

echo Setup docker
install docker
systemctl enable docker
gpasswd -a manybubbles docker


echo Setup ssh agent
sudo -u manybubbles bash <<BASH
  set -xeo pipefail
  cp config/ssh-agent.sh .ssh-agent.sh
BASH
append ~/.bashrc "source .ssh-agent.sh"
