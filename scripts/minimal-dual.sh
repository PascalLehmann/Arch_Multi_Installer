#!/bin/bash
set -euo pipefail
# -e: Beendet das Skript bei Fehlern
# -u: Beendet bei Verwendung undefinierter Variablen
# -o pipefail: Beendet bei Fehlern in einer Pipeline

# 📦 Lade gemeinsame Funktionen/Variablen für Dual-Setup
source "$(dirname "$0")/common_dual.sh"

echo "📦 Minimal Dual-Arch Installer (Arch + Arch)"

# 🧾 Zeige verfügbare Partitionen zur Auswahl
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# 📥 Benutzer wählt EFI-Partition und Root-Partition für diese Arch-Installation
read -rp "EFI-Partition (z.B. /dev/nvme0n1p1): " EFI_PART
read -rp "Root-Partition für diese Arch-Installation (z.B. /dev/nvme0n1p5): " ROOT_PART

# 🧱 Root-Partition vorbereiten (Formatieren, Mounten etc.)
prepare_root_partition "$ROOT_PART"

# 📌 EFI-Partition mounten nach /mnt/boot/efi
mount_efi "$EFI_PART"

# 📦 Installiere minimale Pakete ins neue System
pacstrap /mnt \
  base                 # Arch-Basis
  linux                # Kernel
  linux-firmware       # Firmware für WLAN, Bluetooth etc.
  btrfs-progs          # Btrfs-Dateisystemtools
  git                  # Für spätere Repo-Klonung

# 📄 fstab generieren mit UUIDs
genfstab -U /mnt >> /mnt/etc/fstab

# 🧩 Konfiguration im neuen System (chroot)
arch-chroot /mnt bash -c "
set -euo pipefail

# 🕒 Zeitzone und Uhr
ln -sf /usr/share/zoneinfo/Europe/Berlin /etc/localtime
hwclock --systohc

# 🌍 Sprache und Tastatur
echo 'LANG=de_DE.UTF-8' > /etc/locale.conf
echo 'KEYMAP=de' > /etc/vconsole.conf

# 🖥️ Hostname und Root-Passwort
echo 'archdual' > /etc/hostname
echo 'root:root' | chpasswd

# 🧰 GRUB Bootloader installieren mit OS-Prober
pacman -S --noconfirm grub efibootmgr os-prober

# 🔍 OS-Prober aktivieren, um andere Systeme zu erkennen
echo 'GRUB_DISABLE_OS_PROBER=false' >> /etc/default/grub

# ⚙️ GRUB installieren mit eindeutiger Bootloader-ID
grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader-id=GRUB-ARCH2
grub-mkconfig -o /boot/grub/grub.cfg

# 🧙 GitHub-Repo klonen und Laptop-Skript ausführen
git clone https://github.com/USERNAME/REPO.git /root/installrepo
chmod +x /root/installrepo/scripts/install-laptop.sh
/root/installrepo/scripts/install-laptop.sh
"

# ✅ Abschlussmeldung
echo "✅ Minimal-Dual-Arch-Installation abgeschlossen!"
