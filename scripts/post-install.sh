#!/bin/bash
set -euo pipefail
# -e: Beendet das Skript bei Fehlern
# -u: Beendet bei Verwendung undefinierter Variablen
# -o pipefail: Beendet bei Fehlern in einer Pipeline

# 📦 Lade gemeinsame Variablen und Funktionen (z. B. prepare_base, $USERNAME, $PASSWORD etc.)
source "$(dirname "$0")/common.sh"

# 🧱 Partitionierung, Formatierung und Mounting vorbereiten
prepare_base

# 📦 Installiere Basis- und Laptop-spezifische Pakete ins neue System (/mnt)
pacstrap -K /mnt \
  base                 # Minimaler Arch-Basis-Satz
  linux                # Linux-Kernel
  linux-firmware       # Firmware für WLAN, Bluetooth etc.
  btrfs-progs          # Btrfs-Dateisystemtools
  vim git              # Texteditor + Versionskontrolle
  grub efibootmgr      # Bootloader + EFI-Tools
  sudo                 # Adminrechte für Benutzer
  networkmanager       # Netzwerkverwaltung
  tlp powertop         # Stromspar-Tools für Laptops
  acpi acpid           # ACPI-Unterstützung für Energiemanagement

# 📄 Generiere fstab mit UUIDs und schreibe sie ins neue System
genfstab -U /mnt >> /mnt/etc/fstab

# 🧩 Konfiguriere das neue System im chroot
arch-chroot /mnt /bin/bash <<EOF

# 🕒 Zeitzone setzen
ln -sf /usr/share/zoneinfo/\$TIMEZONE /etc/localtime
hwclock --systohc  # Hardware-Uhr mit Systemzeit synchronisieren

# 🌍 Locale aktivieren und generieren
sed -i "s/^#\s*\$LOCALE/\$LOCALE/" /etc/locale.gen || echo "\$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=\$LOCALE" > /etc/locale.conf
echo "KEYMAP=\$KEYMAP" > /etc/vconsole.conf

# 🖥️ Hostname und Root-Passwort setzen
echo "\$HOSTNAME" > /etc/hostname
echo "root:\$PASSWORD" | chpasswd

# 👤 Benutzer anlegen mit Gruppenrechten
useradd -m -G wheel,video,input -s /bin/bash \$USERNAME
echo "\$USERNAME:\$PASSWORD" | chpasswd

# 🛡️ Sudo für Benutzer aktivieren
sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# ⚙️ Wichtige Dienste aktivieren
systemctl enable NetworkManager   # Netzwerkverwaltung
systemctl enable tlp              # Stromspar-Tool
systemctl enable acpid            # ACPI-Ereignisse (z. B. Deckel schließen)

# 🧰 GRUB Bootloader installieren und konfigurieren
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

EOF

# ✅ Abschlussmeldung
echo "✅ Laptop-Installation abgeschlossen!"
