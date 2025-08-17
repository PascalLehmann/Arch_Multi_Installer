# Führt das Skript mit Bash aus.
# -e: Beendet bei Fehlern.
# -u: Beendet bei nicht gesetzten Variablen.
# -o pipefail: Beendet, wenn ein Befehl in einer Pipe fehlschlägt.
#!/bin/bash
set -euo pipefail

# Fragt den Benutzer nach einer Eingabe mit Prompt $1 und gibt die Eingabe zurück.
ask() { read -rp "$1: " REPLY; echo "$REPLY"; }

# Fragt mit einem Standardwert ($d). Wenn der Benutzer nichts eingibt, wird der Standard verwendet.
ask_default() { local p="$1" d="$2"; read -rp "$p [$d]: " REPLY; echo "${REPLY:-$d}"; }

# Fragt ein Passwort zweimal ab (verdeckt) und prüft, ob beide Eingaben übereinstimmen.
ask_secret() {
  local p="$1" s1 s2
  while true; do
    read -rsp "$p: " s1; echo
    read -rsp "Bitte bestätigen: " s2; echo
    [[ "$s1" == "$s2" ]] && { echo "$s1"; return 0; }
    echo "⚠️ Passwörter stimmen nicht überein."
  done
}

# Start der Funktion zur Vorbereitung der Basisinstallation.
prepare_base() {

# Fragt alle nötigen Systemparameter ab: Zielplatte, Hostname, Benutzername, Passwort, Zeitzone, Locale und Tastaturbelegung.
    DISK=$(ask "Zieldisk (z.B. /dev/sda)")
    HOSTNAME=$(ask_default "Hostname" "archlinux")
    USERNAME=$(ask_default "Benutzername" "user")
    PASSWORD=$(ask_secret "Passwort für $USERNAME")
    TIMEZONE=$(ask_default "Zeitzone" "Europe/Berlin")
    LOCALE=$(ask_default "Locale" "de_DE.UTF-8")
    KEYMAP=$(ask_default "Keymap" "de-latin1")

# Exportiert die Variablen für spätere Verwendung in anderen Skripten oder Funktionen.
    export DISK HOSTNAME USERNAME PASSWORD TIMEZONE LOCALE KEYMAP

# Warnung vor Datenverlust. Nur bei Eingabe von YES wird fortgefahren.
    echo "⚠️ ALLE Daten auf $DISK werden gelöscht!"
    read -rp "Tippe YES zum Bestätigen: " CONFIRM
    [[ "$CONFIRM" == "YES" ]] || exit 1

# Löscht alle Partitionstabellen und Daten auf der Disk.
    sgdisk --zap-all "$DISK"
# Erstellt eine neue GPT-Partitionstabelle.
    parted -s "$DISK" mklabel gpt
# Erstellt eine EFI-Systempartition (ESP) von 1 MiB bis 512 MiB.
    parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB
    parted -s "$DISK" set 1 esp on
# Erstellt eine primäre Partition mit Btrfs für das restliche System.
    parted -s "$DISK" mkpart primary btrfs 512MiB 100%

# Unterscheidet zwischen NVMe- und SATA-Geräten, da NVMe Partitionen mit p1, p2 benannt werden.
    if [[ "$DISK" =~ nvme ]]; then
        EFI_PART="${DISK}p1"
        ROOT_PART="${DISK}p2"
    else
        EFI_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    fi
    export EFI_PART ROOT_PART
    
# Formatiert die EFI-Partition mit FAT32 und die Root-Partition mit Btrfs.
    mkfs.fat -F32 "$EFI_PART"
    mkfs.btrfs -f "$ROOT_PART"

# Mountet die Root-Partition temporär und erstellt Subvolumes für System, Home, Var und Snapshots.
# Danach wird wieder ausgehängt.
    mount "$ROOT_PART" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@snapshots
    umount /mnt

# Hängt die Subvolumes mit Zstandard-Kompression ein.
# Erstellt die nötigen Verzeichnisse und mountet die EFI-Partition unter /mnt/boot.
    mount -o subvol=@,compress=zstd "$ROOT_PART" /mnt
    mkdir -p /mnt/{boot,home,var,.snapshots}
    mount -o subvol=@home,compress=zstd "$ROOT_PART" /mnt/home
    mount -o subvol=@var,compress=zstd "$ROOT_PART" /mnt/var
    mount -o subvol=@snapshots,compress=zstd "$ROOT_PART" /mnt/.snapshots
    mount "$EFI_PART" /mnt/boot
}
