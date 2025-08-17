#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

prepare_base

# Basis + Desktop Pakete
pacstrap -K /mnt base linux linux-firmware btrfs-progs vim git grub efibootmgr sudo networkmanager \
  hyprland xorg-xwayland xdg-desktop-portal-hyprland waybar wofi alacritty \
  pipewire pipewire-pulse wireplumber firefox thunar gvfs greetd greetd-tuigreet

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

useradd -m -G wheel,video,input -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel/%wheel/' /etc/sudoers

systemctl enable NetworkManager
systemctl enable greetd

grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# greetd config
cat >/etc/greetd/config.toml <<GCONF
[terminal]
vt = 1
[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "$USERNAME"
GCONF

su - $USERNAME -c '
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<HCONF
monitor=,preferred,auto,auto
exec-once = waybar
exec-once = wofi --show drun
exec-once = alacritty
HCONF
'
EOF

echo "✅ Desktop-Installation (Hyprland) abgeschlossen!"
