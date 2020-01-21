#!/bin/bash

set -xeo pipefail

timedatectl set-ntp true
lvremove fedora/home -y || true
lvremove fedora/root -y || true
lvremove fedora/swap -y || true
umount /dev/nvme0n1p1 || true
umount /dev/mapper/fedora-root || true
umount /dev/mapper/fedora-home || true
swapoff -a || true
umount /dev/mapper/cryptroot || true
cryptsetup close cryptroot || true
sleep 1
sfdisk /dev/sda << SFDISK
label: gpt

/dev/sda1 : size= 200MiB, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B
/dev/sda2 : size=   4GiB, type=0657FD6D-A4AB-43C4-84E5-0933C84B4F4F
/dev/sda3 :               type=0FC63DAF-8483-4772-8E79-3D69D8477DE4
SFDISK

echo Setting up /
echo -n CRYPTKEY | cryptsetup -v luksFormat /dev/nvme0n1p3 -
echo -n CRYPTKEY | cryptsetup open --key-file - /dev/nvme0n1p3 cryptroot
mkfs.ext4 /dev/mapper/cryptroot
mount /dev/mapper/cryptroot /mnt

echo Setting up /boot
mkfs.fat -F32 /dev/nvme0n1p1
mkdir /mnt/boot
mount /dev/nvme0n1p1 /mnt/boot

echo Setting up swap
mkswap /dev/nvme0n1p2
swapon /dev/nvme0n1p2

echo Setting up basic system
pacman -Sy --noconfirm rxvt-unicode-terminfo archlinux-keyring
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt
ln -sf /usr/share/zoneinfo/America/New_York /etc/localtime
hwclock --systohc
echo en_US.UTF-8 UTF-8 > /etc/locale.gen
locale-gen
echo LANG=en_US.UTF-8 > /etc/locale.conf
echo HOSTNAME > /etc/hostname
echo 127.0.1.1 HOSTNAME.localdomain HOSTNAME >> /etc/hosts
pacman -Sy --noconfirm rxvt-unicode-terminfo archlinux-keyring vim

echo Setting up kernel
pacman -S --noconfirm intel-ucode mkinitcpio
cat <<CONF > /etc/mkinitcpio.conf
MODULES=()
BINARIES=()
FILES=()
HOOKS=(base udev autodetect keyboard keymap consolefont modconf block encrypt filesystems fsck)
CONF
mkinitcpio -P
mkdir /etc/pacman.d/hooks
cat <<CONF > /etc/pacman.d/hooks/100-systemd-boot.hook
[Trigger]
Type = Package
Operation = Upgrade
Target = systemd

[Action]
Description = Updating systemd-boot
When = PostTransaction
Exec = /usr/bin/bootctl update
CONF
bootctl remove
bootctl --path=/boot install
cat <<CONF > /boot/loader/loader.conf
default  arch
timeout  4
console-mode max
editor   no
CONF
cat <<CONF > /boot/loader/entries/arch.conf
title   Arch Linux
linux   /vmlinuz-linux
initrd  /intel-ucode.img
initrd  /initramfs-linux.img
options root=/dev/sda3
CONF
bootctl update
cat <<PASSWD | passwd
tmp
tmp
PASSWD

echo Intalling basic packages
pacman -S --noconfirm iwd openssh bash sudo rxvt-unicode-terminfo rsync mesa
# TODO grep for installing mesa xf86-video-intel
systemctl enable iwd
systemctl enable systemd-resolved
systemctl enable sshd

echo Setting up sudoers
cat <<SUDOERS > /etc/sudoers
root ALL=(ALL) ALL
%wheel ALL=(ALL) ALL
SUDOERS

echo Setting up dhcp
mkdir -p /etc/iwd
cat <<CONF > /etc/iwd/main.conf
[General]
NameResolvingService=systemd
EnableNetworkConfiguration=true
CONF
