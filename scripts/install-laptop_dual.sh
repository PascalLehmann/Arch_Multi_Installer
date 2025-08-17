# Führt das Skript mit Bash aus.
# -euo pipefail: Fehlerbehandlung wie gehabt.
# source .../common.sh: Lädt eine externe Datei mit Hilfsfunktionen (z. B. ask_secret), vermutlich aus dem gleichen Verzeichnis.
#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/common.sh"

# Gibt eine freundliche Statusmeldung aus.
echo "📦 Laptop-Installation (Hyprland)"

# Fragt den gewünschten Benutzernamen ab.
# Fragt das Passwort zweimal ab (verdeckt), mit Bestätigung.
read -rp "Benutzername: " USERNAME
PASSWORD=$(ask_secret "Passwort für $USERNAME")

# Installiert alle nötigen Pakete:
#    Hyprland: moderner Wayland-Window-Manager.
#    Xwayland: für X11-Kompatibilität.
#    Waybar, Wofi, Alacritty: Panel, App-Launcher, Terminal.
#    Pipewire: Audio-Server.
#    Firefox, Thunar, gvfs: Browser, Dateimanager, Dateisystemintegration.
#    greetd + tuigreet: Login-Manager.
#    sudo, networkmanager: Adminrechte und Netzwerkverwaltung.
pacman -S --noconfirm hyprland xorg-xwayland waybar wofi alacritty \
    pipewire pipewire-pulse wireplumber firefox thunar gvfs greetd greetd-tuigreet sudo networkmanager

# Erstellt den Benutzer mit Home-Verzeichnis und Gruppenrechten.
# Setzt das Passwort.
# Aktiviert sudo für Mitglieder der Gruppe wheel.
useradd -m -G wheel,video,input -s /bin/bash "$USERNAME"
echo "$USERNAME:$PASSWORD" | chpasswd
sed -i 's/^# %wheel/%wheel/' /etc/sudoers

# Erstellt die Konfigurationsdatei für greetd.
# Nutzt tuigreet als Login-Frontend und startet Hyprland nach Login.
cat >/etc/greetd/config.toml <<GCONF
[terminal]
vt = 1
[default_session]
command = "tuigreet --time --remember --cmd Hyprland"
user = "$USERNAME"
GCONF

# Aktiviert die Dienste greetd und NetworkManager für den Systemstart.
systemctl enable greetd
systemctl enable NetworkManager

# Führt Befehle als der neue Benutzer aus:
#    Erstellt das Konfigurationsverzeichnis.
#    Schreibt eine einfache hyprland.conf:
#        Automatische Monitor-Erkennung.
#        Startet waybar, wofi und alacritty beim Login.
su - "$USERNAME" -c '
mkdir -p ~/.config/hypr
cat > ~/.config/hypr/hyprland.conf <<HCONF
monitor=,preferred,auto,auto
exec-once = waybar
exec-once = wofi --show drun
exec-once = alacritty
HCONF
'

# Gibt eine Erfolgsmeldung aus.
echo "✅ Laptop-Installation abgeschlossen!"
