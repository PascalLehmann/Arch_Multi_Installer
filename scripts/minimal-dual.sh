#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common_dual.sh"

echo "📦 Minimal Dual-Arch Installer (Arch + Arch)"

lsblk -o NAME,SIZE,TYPE,MOUNTPOINT
read -rp "EFI-Partition (z.B. /dev/nvme0n1p1): " EFI_PART
read -rp "Root-Partition für diese Arch-Installation (z.B. /dev/nvme0n1p5): " ROOT_PART

prepare_root_partition "$ROOT_PART"
mount_efi "$EFI_PART"

# Basisinstallation
pacstrap /mnt base linux linux-firmware btrfs-progs git

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt bash -c "
set -euo pipefail

# Zeitzone & Locale
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc
echo 'LANG=de_DE.UTF-8' > /etc/locale.conf
echo 'KEYMAP=de' > /etc/vconsole.conf
echo 'archdual' > /etc/hostname
echo 'root:root' | chpasswd

# GRUB Master installieren
pacman -S --noconfirm grub efibootmgr os-prober
echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB-ARCH2
grub-mkconfig -o /boot/grub/grub.cfg

# GitHub Repo klonen und Laptop-Skript starten
git clone https://github.com/USERNAME/REPO.git /root/installrepo
chmod +x /root/installrepo/scripts/install-laptop.sh
/root/installrepo/scripts/install-laptop.sh
"

echo "✅ Minimal-Dual-Arch-Installation abgeschlossen!"
