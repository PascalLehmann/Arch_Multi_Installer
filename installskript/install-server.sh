#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

prepare_base

pacstrap -K /mnt base linux linux-firmware btrfs-progs vim git grub efibootmgr sudo networkmanager

genfstab -U /mnt >> /mnt/etc/fstab

arch-chroot /mnt /bin/bash <<EOF
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc
sed -i "s/^#\s*$LOCALE/$LOCALE/" /etc/locale.gen || echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf
echo "$HOSTNAME" > /etc/hostname
echo "root:$PASSWORD" | chpasswd

useradd -m -G wheel -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel/%wheel/' /etc/sudoers

systemctl enable NetworkManager

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

echo "✅ Server-Installation abgeschlossen!"
