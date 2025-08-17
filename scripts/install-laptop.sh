# Fehlerbehandlung aktiv.
# Lädt Variablen und Funktionen aus common.sh (z. B. USERNAME, PASSWORD, TIMEZONE, etc.).
# Führt prepare_base aus – vermutlich Partitionierung, Formatierung und Mounting.
#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

prepare_base

# Basis: Kernel, Firmware, Btrfs, Tools.
# Bootloader: GRUB + EFI.
# Netzwerk: networkmanager.
# Laptop-spezifisch:
#    tlp: Stromspar-Tool für Laptops.
#    powertop: Analyse und Optimierung des Energieverbrauchs.
#    acpi, acpid: ACPI-Unterstützung für Energiemanagement und Events (z. B. Deckel schließen).
pacstrap -K /mnt base linux linux-firmware btrfs-progs vim git grub efibootmgr sudo networkmanager \
  tlp powertop acpi acpid

# Erstellt die Dateisystemtabelle mit UUIDs.
genfstab -U /mnt >> /mnt/etc/fstab

# Alle folgenden Befehle werden im neuen System ausgeführt.
arch-chroot /mnt /bin/bash <<EOF

# Zeitzone und Uhr
ln -sf /usr/share/zoneinfo/$TIMEZONE /etc/localtime
hwclock --systohc

# Locale und Tastatur
sed -i "s/^#\s*$LOCALE/$LOCALE/" /etc/locale.gen || echo "$LOCALE UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE" > /etc/locale.conf
echo "KEYMAP=$KEYMAP" > /etc/vconsole.conf

# Hostname und Root-Passwort
echo "$HOSTNAME" > /etc/hostname
echo "root:$PASSWORD" | chpasswd

# Benutzer anlegen
useradd -m -G wheel,video,input -s /bin/bash $USERNAME
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# Aktiviert Netzwerk und Stromspardienste beim Systemstart.
systemctl enable NetworkManager
systemctl enable tlp
systemctl enable acpid

# Bootloader installieren
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg
EOF

# Abschlussmeldung
echo "✅ Laptop-Installation abgeschlossen!"






# Verbesserungsvorschläge für Laptops
# Wenn du das Skript weiter optimieren willst:
# 🔋 Strom & Hardware
#    tlp-rdw: Für erweiterte TLP-Funktionen (z. B. Dock-Erkennung).
#    thermald: Für bessere CPU-Temperaturkontrolle.
#    xf86-input-libinput: Touchpad- und Eingabegerät-Unterstützung.
#    bluez + bluez-utils: Für Bluetooth.
# Sicherheit
# firewalld oder ufw aktivieren.
# fail2ban für SSH-Schutz.
