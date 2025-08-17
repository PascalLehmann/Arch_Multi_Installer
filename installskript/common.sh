#!/bin/bash
set -euo pipefail

ask() { read -rp "$1: " REPLY; echo "$REPLY"; }
ask_default() { local p="$1" d="$2"; read -rp "$p [$d]: " REPLY; echo "${REPLY:-$d}"; }
ask_secret() {
  local p="$1" s1 s2
  while true; do
    read -rsp "$p: " s1; echo
    read -rsp "Bitte bestätigen: " s2; echo
    [[ "$s1" == "$s2" ]] && { echo "$s1"; return 0; }
    echo "⚠️ Passwörter stimmen nicht überein."
  done
}

prepare_base() {
    DISK=$(ask "Zieldisk (z.B. /dev/sda)")
    HOSTNAME=$(ask_default "Hostname" "archlinux")
    USERNAME=$(ask_default "Benutzername" "user")
    PASSWORD=$(ask_secret "Passwort für $USERNAME")
    TIMEZONE=$(ask_default "Zeitzone" "Europe/Berlin")
    LOCALE=$(ask_default "Locale" "de_DE.UTF-8")
    KEYMAP=$(ask_default "Keymap" "de-latin1")

    export DISK HOSTNAME USERNAME PASSWORD TIMEZONE LOCALE KEYMAP

    echo "⚠️ ALLE Daten auf $DISK werden gelöscht!"
    read -rp "Tippe YES zum Bestätigen: " CONFIRM
    [[ "$CONFIRM" == "YES" ]] || exit 1

    # Partitionierung
    sgdisk --zap-all "$DISK"
    parted -s "$DISK" mklabel gpt
    parted -s "$DISK" mkpart ESP fat32 1MiB 512MiB
    parted -s "$DISK" set 1 esp on
    parted -s "$DISK" mkpart primary btrfs 512MiB 100%

    if [[ "$DISK" =~ nvme ]]; then
        EFI_PART="${DISK}p1"
        ROOT_PART="${DISK}p2"
    else
        EFI_PART="${DISK}1"
        ROOT_PART="${DISK}2"
    fi
    export EFI_PART ROOT_PART

    mkfs.fat -F32 "$EFI_PART"
    mkfs.btrfs -f "$ROOT_PART"

    mount "$ROOT_PART" /mnt
    btrfs subvolume create /mnt/@
    btrfs subvolume create /mnt/@home
    btrfs subvolume create /mnt/@var
    btrfs subvolume create /mnt/@snapshots
    umount /mnt

    mount -o subvol=@,compress=zstd "$ROOT_PART" /mnt
    mkdir -p /mnt/{boot,home,var,.snapshots}
    mount -o subvol=@home,compress=zstd "$ROOT_PART" /mnt/home
    mount -o subvol=@var,compress=zstd "$ROOT_PART" /mnt/var
    mount -o subvol=@snapshots,compress=zstd "$ROOT_PART" /mnt/.snapshots
    mount "$EFI_PART" /mnt/boot
}
