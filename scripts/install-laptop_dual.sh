#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

echo "📦 Laptop-Installation (Hyprland)"

# Interaktive Angaben
read -rp "Benutzername: " USERNAME
PASSWORD=$(ask_secret "Passwort für $USERNAME")

# Installations-Pakete
pacman -S --noconfirm hyprland xorg-xwayland waybar wofi alacritty \
    pipewire pipewire-pulse wireplumber firefox thunar gvfs greetd greetd-tuigreet sudo networkmanager

# Benutzer anlegen
useradd -m -G wheel,video,input -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# greetd konfigurieren
cat >/etc/greetd/config.toml <<GCONF
[terminal]
vt = 1
[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "$USERNAME"
GCONF
systemctl enable greetd
systemctl enable NetworkManager

# Hyprland-Config
su - "$USERNAME" -c '
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<HCONF
monitor=,preferred,auto,auto
exec-once = waybar
exec-once = wofi --show drun
exec-once = alacritty
HCONF
'

echo "✅ Laptop-Installation abgeschlossen!"
