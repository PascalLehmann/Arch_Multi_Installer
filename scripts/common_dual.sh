# Führt das Skript mit Bash aus.
# -e: Beendet bei Fehlern.
# -u: Beendet bei nicht gesetzten Variablen.
# -o pipefail: Beendet, wenn ein Befehl in einer Pipe fehlschlägt.
#!/bin/bash
set -euo pipefail

# Fragt den Benutzer mit einem Prompt ($1) und gibt die Eingabe zurück.
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

# Funktion zur Formatierung und Einbindung der Root-Partition:
#  $1 ist der übergebene Partitionspfad (z. B. /dev/sda2).
#  mkfs.btrfs -f: Formatiert die Partition mit Btrfs.
#  mount: Hängt sie unter /mnt ein – das Zielverzeichnis für die spätere Systeminstallation.
prepare_root_partition() {
    ROOT_PART="$1"
    mkfs.btrfs -f "$ROOT_PART"
    mount "$ROOT_PART" /mnt
}


# Funktion zum Einbinden der EFI-Systempartition:
#  $1 ist der übergebene Partitionspfad (z. B. /dev/sda1 oder /dev/nvme0n1p1).
#  Erstellt das Verzeichnis /mnt/boot/efi, falls es nicht existiert.
#  Hängt die EFI-Partition dort ein – wichtig für UEFI-Boot.
mount_efi() {
    EFI_PART="$1"
    mkdir -p /mnt/boot/efi
    mount "$EFI_PART" /mnt/boot/efi
}
