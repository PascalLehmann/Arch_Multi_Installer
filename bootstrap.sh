#!/bin/bash
set -euo pipefail

REPO_USER="USERNAME"
REPO_NAME="REPO"

# Internet check
ping -c1 archlinux.org >/dev/null 2>&1 || {
    echo "❌ Keine Internetverbindung!"
    exit 1
}

# git sicherstellen
if ! command -v git >/dev/null 2>&1; then
    pacman -Sy --noconfirm git
fi

# Repo klonen
rm -rf /tmp/arch-install
git clone https://github.com/$REPO_USER/$REPO_NAME.git /tmp/arch-install
cd /tmp/arch-install

# verfügbare Install-Skripte finden
SCRIPTS=(install-*.sh)

if [ ${#SCRIPTS[@]} -eq 0 ]; then
    echo "❌ Keine install-*.sh Skripte im Repo gefunden!"
    exit 1
fi

echo "📦 Gefundene Installationsskripte:"
select SCRIPT in "${SCRIPTS[@]}"; do
    if [[ -n "$SCRIPT" ]]; then
        echo "🚀 Starte $SCRIPT ..."
        chmod +x "$SCRIPT"
        exec "./$SCRIPT"
    else
        echo "Ungültige Auswahl!"
    fi
done
