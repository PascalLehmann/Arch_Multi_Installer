# Führt das Skript mit Bash aus.
# Fehlerbehandlung wie gehabt.
# Lädt Hilfsfunktionen und Variablen aus common.sh (z. B. prepare_base, USERNAME, PASSWORD, TIMEZONE, etc.).
#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Führt die Funktion prepare_base aus, die Partitionierung, Formatierung und Mounting übernimmt (aus vorherigem Skript).
prepare_base

# Installiert das Basissystem und alle benötigten Pakete:
#     Kernel, Firmware, Btrfs, Tools.
#     Bootloader: grub, efibootmgr.
#     Desktop: Hyprland + Wayland-Komponenten.
#     Audio, Netzwerk, Login-Manager, Browser, Dateimanager.
pacstrap -K /mnt base linux linux-firmware btrfs-progs vim git grub efibootmgr sudo networkmanager \
  hyprland xorg-xwayland xdg-desktop-portal-hyprland waybar wofi alacritty \
  pipewire pipewire-pulse wireplumber firefox thunar gvfs greetd greetd-tuigreet

# Erstellt die Dateisystemtabelle mit UUIDs und schreibt sie ins neue System.
genfstab -U /mnt >> /mnt/etc/fstab

# Führt alle folgenden Befehle im neuen System aus (/mnt wird zur Root).
arch-chroot /mnt /bin/bash <<EOF

# Setzt die Zeitzone.
# Synchronisiert die Hardware-Uhr mit der Systemzeit.
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Aktiviert die gewünschte Locale.
# Generiert Sprachdateien.
# Setzt Sprache und Tastaturbelegung.
sed -i "s/^#\s*$LOCALE/$LOCALE/" /etc/locale.gen || echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Setzt den Rechnernamen.
# Vergibt das Root-Passwort.
echo "$HOSTNAME" > /etc/hostname
echo "root:$PASSWORD" | chpasswd

# Erstellt Benutzer mit Home-Verzeichnis und Gruppenrechten.
# Setzt Passwort.
# Aktiviert sudo für Gruppe wheel.
useradd -m -G wheel,video,input -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# Aktiviert Netzwerk und Login-Manager für den Systemstart.
systemctl enable NetworkManager
systemctl enable greetd

# Installiert GRUB für UEFI.
# Erstellt die GRUB-Konfiguration.
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# Erstellt die Konfigurationsdatei für greetd.
# Nutzt tuigreet als Login-Frontend und startet Hyprland nach Login.
cat >/etc/greetd/config.toml <<GCONF
[terminal]
vt = 1
[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "$USERNAME"
GCONF

# Führt Befehle als der neue Benutzer aus:
#    Erstellt Konfigurationsverzeichnis.
#    Schreibt eine einfache hyprland.conf mit Autostart von Waybar, Wofi und Alacritty.
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

# Gibt eine Erfolgsmeldung aus.
echo "✅ Desktop-Installation (Hyprland) abgeschlossen!"
