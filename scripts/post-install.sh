#!/bin/bash
set -euo pipefail

# 🧠 Variablen – passe sie an dein System an
USERNAME="dein-benutzername"
USER_HOME="/home/$USERNAME"
DOTFILES_REPO="https://github.com/dein-benutzername/dotfiles.git"  # Optional, wenn du später eines hast

# 📦 Paketquellen optimieren mit reflector
echo "🔄 Aktualisiere Spiegelserver..."
sudo pacman -Syu --noconfirm reflector
sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist

# 🧙 Installiere yay als AUR-Helfer
echo "📦 Installiere yay..."
sudo pacman -S --needed --noconfirm base-devel git
sudo -u "$USERNAME" bash <<EOF
cd ~
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF

# 🐚 Installiere Zsh + Oh My Zsh
echo "🐚 Installiere Zsh und Oh My Zsh..."
sudo pacman -S --noconfirm zsh
sudo -u "$USERNAME" bash <<EOF
chsh -s /bin/zsh
sh -c "\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
EOF

# 📁 Erstelle Standardordner für Benutzer (Dokumente, Downloads etc.)
echo "📁 Erstelle Standardordner..."
sudo -u "$USERNAME" xdg-user-dirs-update

# 🔋 Laptop-spezifische Stromsparpakete installieren
echo "🔋 Installiere Laptop-Tweaks..."
sudo pacman -S --noconfirm tlp powertop acpi acpid thermald xf86-input-libinput
sudo systemctl enable tlp
sudo systemctl enable acpid
sudo systemctl enable thermald

# 🛡️ Aktiviere Firewall mit UFW
echo "🛡️ Aktiviere Firewall..."
sudo pacman -S --noconfirm ufw
sudo systemctl enable ufw
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable

# 🖥️ Hyprland-Konfiguration vorbereiten (wenn keine Dotfiles vorhanden)
echo "🖥️ Erstelle einfache Hyprland-Konfiguration..."
sudo -u "$USERNAME" bash <<EOF
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<HCONF
monitor=,preferred,auto,auto
exec-once = waybar
exec-once = wofi --show drun
exec-once = alacritty
HCONF
EOF

# 🛠️ Dotfiles klonen (optional, wenn du später ein Repo hast)
# echo "🛠️ Klone Dotfiles..."
# sudo -u "$USERNAME" bash <<EOF
# cd ~
# git clone "$DOTFILES_REPO" dotfiles
# cd dotfiles
# ./install.sh || echo "⚠️ Dotfiles-Skript nicht gefunden oder fehlgeschlagen"
# EOF

echo "✅ Post-Install abgeschlossen!"
