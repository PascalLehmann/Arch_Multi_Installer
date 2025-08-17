#!/bin/bash
set -euo pipefail

# Interaktive Abfragen
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

# Basis Partitionierung für neue Root
prepare_root_partition() {
    ROOT_PART="$1"
    mkfs.btrfs -f "$ROOT_PART"
    mount "$ROOT_PART" /mnt
}

# EFI einbinden
mount_efi() {
    EFI_PART="$1"
    mkdir -p /mnt/boot/efi
    mount "$EFI_PART" /mnt/boot/efi
}
