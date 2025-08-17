# Shebang: Gibt an, dass das Skript mit Bash ausgeführt werden soll.
#!/bin/bash

# -e: Beendet das Skript bei einem Fehler.
# -u: Beendet das Skript, wenn eine nicht gesetzte Variable verwendet wird.
# -o pipefail: Beendet das Skript, wenn ein Befehl in einer Pipe fehlschlägt.
set -euo pipefail

# REPO_USER: GitHub-Benutzername.
# REPO_NAME: Name des GitHub-Repositories.
# SCRIPT_DIR: Unterordner im Repository, der die Installationsskripte enthält.
REPO_USER="USERNAME"
REPO_NAME="REPO"
SCRIPT_DIR="scripts"   # 👈 hier den Ordner im Repo angeben

# Versucht, archlinux.org einmal anzupingen.
# Wenn das fehlschlägt, wird eine Fehlermeldung ausgegeben und das Skript beendet.
ping -c1 archlinux.org >/dev/null 2>&1 || {
    echo "❌ Keine Internetverbindung!"
    exit 1
}

# Prüft, ob git verfügbar ist.
# Falls nicht, wird es mit pacman (Arch Linux Paketmanager) installiert.
if ! command -v git >/dev/null 2>&1; then
    pacman -Sy --noconfirm git
fi

# Löscht ggf. ein altes /tmp/arch-install Verzeichnis.
# Klont das angegebene GitHub-Repo in /tmp/arch-install.
# Wechselt in das geklonte Verzeichnis.
rm -rf /tmp/arch-install
git clone https://github.com/$REPO_USER/$REPO_NAME.git /tmp/arch-install
cd /tmp/arch-install

# Prüft, ob der angegebene Ordner (scripts) im Repo existiert.
# Falls nicht, wird das Skript mit Fehlermeldung beendet.
if [ ! -d "$SCRIPT_DIR" ]; then
    echo "❌ Verzeichnis $SCRIPT_DIR existiert nicht im Repo!"
    exit 1
fi

# Wechselt in das Verzeichnis mit den Installationsskripten.
cd "$SCRIPT_DIR"

# Sammelt alle Dateien, die mit install- beginnen und auf .sh enden.
SCRIPTS=(install-*.sh)

# Prüft, ob überhaupt Skripte gefunden wurden.
# Falls nicht, wird das Skript beendet.
if [ ${#SCRIPTS[@]} -eq 0 ]; then
    echo "❌ Keine install-*.sh Skripte im Verzeichnis $SCRIPT_DIR gefunden!"
    exit 1
fi

# Zeigt ein Auswahlmenü mit den gefundenen Skripten.
# select erzeugt eine nummerierte Liste zur Auswahl.
echo "📦 Gefundene Installationsskripte:"
select SCRIPT in "${SCRIPTS[@]}"; do
# Wenn eine gültige Auswahl getroffen wurde:
#    Skript ausführbar machen (chmod +x)
#    Skript ausführen mit exec (ersetzt das aktuelle Skript durch das neue)
    if [[ -n "$SCRIPT" ]]; then
        echo "🚀 Starte $SCRIPT ..."
        chmod +x "$SCRIPT"
        exec "./$SCRIPT"
# Falls keine gültige Auswahl getroffen wurde, wird eine Fehlermeldung ausgegeben.
    else
        echo "Ungültige Auswahl!"
    fi
done
