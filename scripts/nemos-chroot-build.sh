#!/usr/bin/env bash
# ============================================================================
# nemOS - Fonctions d'aide pour la construction dans le chroot
# Ces fonctions sont appelées durant la construction archiso dans le chroot.
# Chaque fonction est autonome et peut être appelée individuellement.
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Variables globales de configuration nemOS
# ---------------------------------------------------------------------------
NEMOS_HOSTNAME="nemOS"
NEMOS_TIMEZONE="Europe/Paris"
NEMOS_LOCALE="fr_FR.UTF-8"
NEMOS_LANG="fr"
NEMOS_DEFAULT_USER="nem"
NEMOS_FULL_NAME="Utilisateur nemOS"
NEMOS_DISPLAY_MANAGER="lightdm"
NEMOS_SESSION="openbox"
NEMOS_VERSION="1.0"

# Chemins des ressources nemOS
NEMOS_ASSETS_DIR="/usr/local/share/nemos-assets"
NEMOS_WALLPAPER_SRC="/tmp/nemos-build/nem/airootfs/usr/share/backgrounds"
NEMOS_THEME_SRC="/tmp/nemos-build/nem/airootfs/usr/share/themes"
NEMOS_ICON_SRC="/tmp/nemos-build/nem/airootfs/usr/share/icons"

# Couleurs pour les messages (même si dans chroot, utile si connecté à un tty)
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

msg_info() { echo -e "${BLUE}[CHROOT]${NC} $1" 2>/dev/null || echo "[CHROOT] $1"; }
msg_ok()   { echo -e "${GREEN}[OK]${NC} $1" 2>/dev/null || echo "[OK] $1"; }
msg_warn() { echo -e "${YELLOW}[!]${NC} $1" 2>/dev/null || echo "[!] $1"; }

# ============================================================================
# configure_locale() - Configurer la locale française
#
# Active la locale fr_FR.UTF-8 comme locale par défaut du système.
# Décommente les entrées nécessaires dans /etc/locale.gen et
# génère les locales avec locale-gen.
# ============================================================================
configure_locale() {
    msg_info "Configuration de la locale française..."

    # Décommenter fr_FR.UTF-8 dans locale.gen
    if [[ -f /etc/locale.gen ]]; then
        sed -i 's/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
        sed -i 's/#fr_FR ISO-8859-1/fr_FR ISO-8859-1/' /etc/locale.gen
        sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        sed -i 's/#en_US ISO-8859-1/en_US ISO-8859-1/' /etc/locale.gen

        # Générer les locales
        locale-gen 2>/dev/null || true
    fi

    # Écrire le fichier de configuration de la locale
    cat > /etc/locale.conf <<EOF
LANG=${NEMOS_LOCALE}
LANGUAGE=fr:en:fr_FR:en_US
LC_MESSAGES=fr_FR.UTF-8
LC_TIME=fr_FR.UTF-8
LC_NUMERIC=fr_FR.UTF-8
LC_MONETARY=fr_FR.UTF-8
LC_PAPER=fr_FR.UTF-8
LC_NAME=fr_FR.UTF-8
LC_ADDRESS=fr_FR.UTF-8
LC_TELEPHONE=fr_FR.UTF-8
LC_MEASUREMENT=fr_FR.UTF-8
LC_IDENTIFICATION=fr_FR.UTF-8
EOF

    # Configurer la clé console en français
    cat > /etc/vconsole.conf <<EOF
KEYMAP=fr-latin9
FONT=lat0-16
FONT_MAP=8859-15
EOF

    # Configurer la disposition du clavier pour X11
    mkdir -p /etc/X11/xorg.conf.d
    cat > /etc/X11/xorg.conf.d/00-keyboard.conf <<EOF
# Configuration du clavier pour nemOS
Section "InputClass"
    Identifier "system-keyboard"
    MatchIsKeyboard "on"
    Option "XkbLayout" "fr"
    Option "XkbVariant" "latin9"
    Option "XkbOptions" "terminate:ctrl_alt_bksp"
EndSection
EOF

    msg_ok "Locale française configurée (${NEMOS_LOCALE})."
}

# ============================================================================
# configure_timezone() - Configurer le fuseau horaire
#
# Définit le fuseau horaire sur Europe/Paris et active l'horloge matérielle
# en temps UTC (standard Linux).
# ============================================================================
configure_timezone() {
    msg_info "Configuration du fuseau horaire (${NEMOS_TIMEZONE})..."

    # Lien symbolique vers le fuseau horaire
    if [[ -f "/usr/share/zoneinfo/${NEMOS_TIMEZONE}" ]]; then
        ln -sf "/usr/share/zoneinfo/${NEMOS_TIMEZONE}" /etc/localtime
        msg_ok "Fuseau horaire défini sur ${NEMOS_TIMEZONE}."
    else
        msg_warn "Fuseau horaire ${NEMOS_TIMEZONE} introuvable."
        return 1
    fi

    # Configurer l'horloge matérielle en UTC
    if command -v hwclock &>/dev/null; then
        hwclock --systohc --utc 2>/dev/null || true
    fi

    # Écrire le fichier adjtime pour persister le choix UTC
    cat > /etc/adjtime <<EOF
0.0 0 0.0
0
UTC
EOF

    msg_ok "Horloge matérielle configurée en UTC."
}

# ============================================================================
# configure_hostname() - Configurer le nom d'hôte
#
# Définit le nom d'hôte du système et met à jour /etc/hosts.
# ============================================================================
configure_hostname() {
    msg_info "Configuration du nom d'hôte (${NEMOS_HOSTNAME})..."

    # Écrire le nom d'hôte
    echo "${NEMOS_HOSTNAME}" > /etc/hostname

    # Mettre à jour /etc/hosts avec les entrées standard
    cat > /etc/hosts <<EOF
# /etc/hosts - Résolution statique des noms d'hôtes
127.0.0.1       localhost
127.0.1.1       ${NEMOS_HOSTNAME}.localdomain  ${NEMOS_HOSTNAME}

# IPv6
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF

    msg_ok "Nom d'hôte défini sur ${NEMOS_HOSTNAME}."
}

# ============================================================================
# enable_services() - Activer les services essentiels au démarrage
#
# Active les services systemd nécessaires au bon fonctionnement de nemOS.
# Chaque service est vérifié avant activation.
# ============================================================================
enable_services() {
    msg_info "Activation des services système essentiels..."

    # Liste des services à activer avec une description
    # Format : "service:unit_type:description"
    local services=(
        "NetworkManager:service:Gestionnaire de réseau"
        "bluetooth:service:Support Bluetooth"
        "cups:service:Système d'impression"
        "dbus-broker:service:Bus de messages D-Bus"
        "lightdm:service:Gestionnaire de connexion graphique"
        "cronie:service:Planificateur de tâches"
        "fstrim:timer:TRIM hebdomadaire pour SSD"
        "pamac:service:Démon de gestion de paquets (si installé)"
        "haveged:service:Générateur d'entropie"
        "systemd-timesyncd:service:Synchronisation de l'heure"
    )

    local activated=0
    local skipped=0

    for entry in "${services[@]}"; do
        local svc="${entry%%:*}"
        local desc="${entry#*:}"
        desc="${desc#*:}"

        # Vérifier si l'unité existe
        if systemctl list-unit-files "${svc}" &>/dev/null; then
            systemctl enable "${svc}" 2>/dev/null && {
                msg_ok "  ${svc} activé — ${desc}"
                ((activated++)) || true
            } || {
                msg_warn "  ${svc} : échec de l'activation."
                ((skipped++)) || true
            }
        else
            msg_info "  ${svc} non installé, ignoré — ${desc}"
            ((skipped++)) || true
        fi
    done

    msg_info "Services activés : ${activated}, ignorés : ${skipped}."

    # Désactiver les services non souhaités
    local disable_services=(
        "gdm"
        "sddm"
        "lxdm"
        "xdm"
        "slim"
    )

    for svc in "${disable_services[@]}"; do
        if systemctl is-enabled "${svc}" 2>/dev/null; then
            systemctl disable "${svc}" 2>/dev/null || true
            msg_info "  ${svc} désactivé (gestionnaire de connexion alternatif)."
        fi
    done
}

# ============================================================================
# create_user() - Créer l'utilisateur par défaut
#
# Crée l'utilisateur "nem" avec les groupes appropriés et l'accès sudo.
# ============================================================================
create_user() {
    msg_info "Création de l'utilisateur par défaut (${NEMOS_DEFAULT_USER})..."

    local user="${NEMOS_DEFAULT_USER}"

    # Vérifier si l'utilisateur existe déjà
    if id "${user}" &>/dev/null; then
        msg_warn "L'utilisateur '${user}' existe déjà."
        return 0
    fi

    # Créer l'utilisateur avec les groupes standard
    useradd -m \
        -c "${NEMOS_FULL_NAME}" \
        -s /bin/bash \
        -G users,audio,video,power,storage,input,lp,network,scanner,log \
        "${user}"

    # Définir un mot de passe par défaut (l'utilisateur devra le changer)
    echo "${user}:nemOS" | chpasswd

    # Forcer le changement de mot de passe à la première connexion
    chage -d 0 "${user}" 2>/dev/null || true

    # Configurer sudo
    # S'assurer que le groupe wheel existe
    if ! getent group wheel &>/dev/null; then
        groupadd wheel
    fi

    # Ajouter l'utilisateur au groupe wheel
    usermod -aG wheel "${user}"

    # Configurer sudoers pour le groupe wheel
    mkdir -p /etc/sudoers.d

    # S'assurer que le fichier sudoers inclut le groupe wheel
    if ! grep -q "^%wheel" /etc/sudoers 2>/dev/null; then
        echo "%wheel ALL=(ALL) ALL" >> /etc/sudoers
    fi

    # Créer une configuration sudoers dédiée à nemOS
    cat > /etc/sudoers.d/nemos-default <<EOF
# Configuration sudo par défaut de nemOS
# L'utilisateur par défaut a tous les droits sudo
${user} ALL=(ALL) ALL

# Conserver les variables d'environnement graphiques
Defaults:${user} env_keep += "DISPLAY XAUTHORITY WAYLAND_DISPLAY"
Defaults:${user} env_keep += "QT_QPA_PLATFORMTHEME"
EOF

    chmod 0440 /etc/sudoers.d/nemos-default

    # Configurer le fichier .bashrc de l'utilisateur
    local user_home
    user_home="$(eval echo "~${user}")"

    cat >> "${user_home}/.bashrc" <<'BASHRC'

# --- Configuration personnalisée nemOS ---
# Alias utiles
alias ll='ls -la --color=auto'
alias la='ls -a --color=auto'
alias l='ls -CF --color=auto'
alias grep='grep --color=auto'
alias egrep='egrep --color=auto'
alias fgrep='fgrep --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias update='sudo pacman -Syu'
alias install='sudo pacman -S'
alias remove='sudo pacman -Rs'
alias search='pacman -Ss'
alias nemos-services='sudo /usr/local/bin/nemos-services'

# Prompt personnalisé
PS1='\[\033[01;34m\]nemOS\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '

# Chemins supplémentaires
if [[ -d "$HOME/.local/bin" ]]; then
    export PATH="$HOME/.local/bin:$PATH"
fi
BASHRC

    chown "${user}:${user}" "${user_home}/.bashrc"

    msg_ok "Utilisateur '${user}' créé avec accès sudo."
}

# ============================================================================
# configure_display() - Configurer le gestionnaire de connexion
#
# Configure LightDM (ou XDM en fallback) pour la session OpenBox.
# Personnalise l'apparence du gestionnaire de connexion.
# ============================================================================
configure_display() {
    msg_info "Configuration de l'affichage graphique..."

    # Configurer LightDM comme gestionnaire de connexion par défaut
    if [[ -f /usr/bin/lightdm ]]; then
        msg_info "Configuration de LightDM..."

        # Créer le répertoire de configuration
        mkdir -p /etc/lightdm

        # Configuration principale de LightDM
        cat > /etc/lightdm/lightdm.conf <<EOF
# Configuration LightDM pour nemOS
[Seat:*]
autologin-guest=false
greeter-session=lightdm-greeter
user-session=${NEMOS_SESSION}
greeter-hide-users=false
allow-guest=false
session-wrapper=/etc/lightdm/Xsession

[Display]
# Autoriser le redémarrage et l'extinction
allow-user-switching=true
greeter-allow-guest=false

[XDMCPServer]
enabled=false

[VNCServer]
enabled=false
EOF

        # Configuration du greeter (GTK)
        mkdir -p /etc/lightdm/lightdm-gtk-greeter.conf.d
        cat > /etc/lightdm/lightdm-gtk-greeter.conf.d/01_nemos.conf <<EOF
# Configuration du greeter GTK pour nemOS
[greeter]
theme-name=nemOS
icon-theme-name=nemOS-icons
font-name=Sans 11
background=/usr/share/backgrounds/nemos-default.jpg
default-user=${NEMOS_DEFAULT_USER}
hide-user-image=false
show-clock=true
clock-format=%H:%M
position=50%,center 50%,center
EOF

        # Activer LightDM
        systemctl disable display-manager 2>/dev/null || true
        systemctl enable lightdm 2>/dev/null || true

        msg_ok "LightDM configuré pour la session ${NEMOS_SESSION}."
    else
        msg_warn "LightDM non trouvé. Tentative de configuration de XDM..."
        configure_xdm
    fi

    # Configurer la session OpenBox par défaut
    configure_openbox_session
}

# Configuration de secours XDM
configure_xdm() {
    if [[ ! -f /usr/bin/xdm ]]; then
        msg_warn "XDM non trouvé non plus. L'utilisateur devra lancer startx manuellement."
        return 1
    fi

    # Configurer XDM
    mkdir -p /etc/X11/xdm
    cat > /etc/X11/xdm/Xresources <<EOF
! Configuration XDM pour nemOS
xlogin*login.translations: #override\
    <Key>Return: #set\&Abort\n\
    <Key>F1: set\&Abort\n\
    Ctrl<Key>Return: #set\&Abort
xlogin*greeting: nemOS ${NEMOS_VERSION}
xlogin*namePrompt: Identifiant\040:
xlogin*passwdPrompt: Mot de passe\040:
EOF

    # Activer XDM en dernier recours
    systemctl enable xdm 2>/dev/null || true
    msg_ok "XDM configuré en tant que gestionnaire de connexion de secours."
}

# Configuration de la session OpenBox
configure_openbox_session() {
    msg_info "Configuration de la session OpenBox..."

    # Créer le fichier de session desktop
    mkdir -p /usr/share/xsessions
    cat > /usr/share/xsessions/nemos-openbox.desktop <<EOF
[Desktop Entry]
Name=nemOS (Openbox)
Comment=Session nemOS avec Openbox
Exec=/usr/bin/openbox-session
Type=Application
DesktopNames=nemOS;Openbox;
Keywords=launch;openbox;desktop;session;
EOF

    # Créer la configuration OpenBox par défaut
    mkdir -p /etc/xdg/openbox
    cat > /etc/xdg/openbox/rc.xml <<'OPENBOX'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc" xmlns:xi="http://www.w3.org/2001/XInclude">
  <resistance>
    <strength>10</strength>
    <window_strength>10</window_strength>
    <desktop_strength>50</desktop_strength>
  </resistance>

  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
    <focusLast>yes</focusLast>
    <underMouse>no</underMouse>
    <raiseOnFocus>no</raiseOnFocus>
    <unfocusOnLeave>no</unfocusOnLeave>
  </focus>

  <placement>
    <policy>Smart</policy>
    <center>yes</center>
    <monitor>Any</monitor>
    <primaryMonitor>1</primaryMonitor>
  </placement>

  <theme>
    <name>nemOS</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
    <font place="ActiveWindow">
      <name>Sans</name>
      <size>10</size>
      <weight>bold</weight>
    </font>
    <font place="InactiveWindow">
      <name>Sans</name>
      <size>10</size>
    </font>
  </theme>

  <desktops>
    <number>4</number>
    <firstdesk>1</firstdesk>
    <names>
      <name>1</name>
      <name>2</name>
      <name>3</name>
      <name>4</name>
    </names>
  </desktops>

  <resize>
    <drawContents>yes</drawContents>
    <popupShow>Nonpixel</popupShow>
    <popupPosition>Center</popupPosition>
    <popupFixedPosition>no</popupFixedPosition>
  </resize>

  <margins>
    <top>0</top>
    <bottom>0</bottom>
    <left>0</left>
    <right>0</right>
  </margins>

  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>

    <!-- Raccourcis clavier globaux -->
    <keybind key="A-F2">
      <action name="Execute"><command>rofi -show run</command></action>
    </keybind>
    <keybind key="A-F3">
      <action name="Execute"><command>rofi -show drun</command></action>
    </keybind>
    <keybind key="C-A-t">
      <action name="Execute"><command>alacritty</command></action>
    </keybind>
    <keybind key="C-A-l">
      <action name="Execute"><command>light-locker-command -l</command></action>
    </keybind>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>

    <!-- Navigation entre bureaux -->
    <keybind key="C-A-Left">
      <action name="DesktopLeft"><wrap>yes</wrap></action>
    </keybind>
    <keybind key="C-A-Right">
      <action name="DesktopRight"><wrap>yes</wrap></action>
    </keybind>
    <keybind key="C-A-Up">
      <action name="DesktopUp"><wrap>yes</wrap></action>
    </keybind>
    <keybind key="C-A-Down">
      <action name="DesktopDown"><wrap>yes</wrap></action>
    </keybind>

    <!-- Déplacement de fenêtres entre bureaux -->
    <keybind key="S-A-Left">
      <action name="SendToDesktopLeft"><wrap>no</wrap></action>
    </keybind>
    <keybind key="S-A-Right">
      <action name="SendToDesktopRight"><wrap>no</wrap></action>
    </keybind>

    <!-- Redémarrage / fermeture -->
    <keybind key="C-A-BackSpace">
      <action name="Restart"/>
    </keybind>
  </keyboard>

  <mouse>
    <dragThreshold>8</dragThreshold>
    <doubleClickTime>200</doubleClickTime>
    <screenEdgeWarpTime>400</screenEdgeWarpTime>
    <context name="Frame">
      <mousebind button="A-Left" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
        <action name="Unshade"/>
      </mousebind>
      <mousebind button="A-Left" action="Drag">
        <action name="Move"/>
      </mousebind>
      <mousebind button="A-Right" action="Press">
        <action name="Focus"/>
        <action name="Raise"/>
        <action name="ShowMenu"><menu>client-menu</menu></action>
      </mousebind>
    </context>
    <context name="Titlebar">
      <mousebind button="A-Left" action="Drag"><action name="Move"/></mousebind>
      <mousebind button="A-Left" action="DoubleClick"><action name="ToggleShade"/></mousebind>
      <mousebind button="A-Middle" action="Press"><action name="Lower"/></mousebind>
    </context>
    <context name="Close">
      <mousebind button="A-Left" action="Press"><action name="Close"/></mousebind>
    </context>
    <context name="Desktop">
      <mousebind button="A-Left" action="Press"><action name="Focus"/><action name="Raise"/></mousebind>
      <mousebind button="C-A-Left" action="Press"><action name="GoToDesktop"><to>previous</to></action></mousebind>
      <mousebind button="A-Right" action="Press"><action name="ShowMenu"><menu>root-menu</menu></action></mousebind>
    </context>
  </mouse>

  <menu>
    <file>menu.xml</file>
    <hideDelay>200</hideDelay>
    <middle>no</middle>
    <submenuShowDelay>100</submenuShowDelay>
  </menu>

  <applications>
    <application name="*" class="*">
      <focus>yes</focus>
      <decor>yes</decor>
      <shade>no</shade>
      <maximized>no</maximized>
    </application>
  </applications>

  <windowRules>
    <windowRule identifier="*" type="dialog">
      <position force="yes"><x>center</x><y>center</y></position>
    </windowRule>
  </windowRules>
</openbox_config>
OPENBOX

    # Créer le menu OpenBox
    cat > /etc/xdg/openbox/menu.xml <<'MENU'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_menu xmlns="http://openbox.org/3.4/menu">
  <menu id="root-menu" label="nemOS">
    <menu id="apps-accessories" label="Accessoires">
      <item label="Terminal"><action name="Execute"><command>alacritty</command></action></item>
      <item label="Gestionnaire de fichiers"><action name="Execute"><command>pcmanfm</command></action></item>
      <item label="Éditeur de texte"><action name="Execute"><command>geany</command></action></item>
    </menu>
    <menu id="apps-system" label="Système">
      <item label="Gestionnaire de paquets"><action name="Execute"><command>pamac-manager</command></action></item>
      <item label="Moniteur système"><action name="Execute"><command>htop</command></action></item>
      <item label="Services nemOS"><action name="Execute"><command>alacritty -e sudo nemos-services</command></action></item>
    </menu>
    <separator/>
    <menu id="apps-settings" label="Paramètres">
      <item label="Personnalisation OpenBox"><action name="Execute"><command>obconf</command></action></item>
      <item label="Fond d'écran"><action name="Execute"><command>nitrogen</command></action></item>
      <item label="Panneau tint2"><action name="Execute"><command>tint2conf</command></action></item>
    </menu>
    <separator/>
    <item label="Déconnexion"><action name="Exit"/></item>
    <item label="Redémarrer"><action name="Restart"/></item>
  </menu>
</openbox_menu>
MENU

    # Créer l'autostart
    cat > /etc/xdg/openbox/autostart <<'AUTOSTART'
# Autostart nemOS - OpenBox
# Lancer les applications au démarrage de la session

# Fond d'écran
nitrogen --restore &

# Barre de tâches tint2
tint2 &

# Démon de notification
dunst &

# Gestionnaire de presse-papiers
clipman -d &

# Vérificateur de mise à jour (en arrière-plan, silencieux)
(sleep 30 && checkupdates) &
AUTOSTART

    # Autostart spécifique utilisateur
    mkdir -p "/home/${NEMOS_DEFAULT_USER}/.config/openbox"
    cp /etc/xdg/openbox/autostart "/home/${NEMOS_DEFAULT_USER}/.config/openbox/autostart" 2>/dev/null || true
    chown -R "${NEMOS_DEFAULT_USER}:${NEMOS_DEFAULT_USER}" "/home/${NEMOS_DEFAULT_USER}/.config" 2>/dev/null || true

    msg_ok "Session OpenBox configurée."
}

# ============================================================================
# install_nemos_assets() - Installer les ressources nemOS
#
# Copie les fonds d'écran, icônes et thèmes vers les emplacements système.
# Crée le répertoire de ressources centralisé.
# ============================================================================
install_nemos_assets() {
    msg_info "Installation des ressources visuelles nemOS..."

    # Créer les répertoires de destination
    mkdir -p /usr/share/backgrounds/nemos-wallpapers
    mkdir -p /usr/share/themes
    mkdir -p /usr/share/icons
    mkdir -p "${NEMOS_ASSETS_DIR}"

    # Copier les fonds d'écran (depuis le profil si disponibles)
    if [[ -d "${NEMOS_WALLPAPER_SRC}/nemos-wallpapers" ]]; then
        cp -r "${NEMOS_WALLPAPER_SRC}/nemos-wallpapers"/* \
              /usr/share/backgrounds/nemos-wallpapers/ 2>/dev/null || true
        msg_ok "Fonds d'écran copiés."
    elif [[ -d "${NEMOS_WALLPAPER_SRC}" ]]; then
        cp -r "${NEMOS_WALLPAPER_SRC}"/* \
              /usr/share/backgrounds/nemos-wallpapers/ 2>/dev/null || true
        msg_ok "Fonds d'écran copiés (depuis le répertoire par défaut)."
    else
        msg_warn "Aucun fond d'écran source trouvé. Création d'un fond par défaut."

        # Créer un fond d'écran SVG par défaut avec le logo nemOS
        cat > /usr/share/backgrounds/nemos-wallpapers/nemos-default.svg <<'SVG'
<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" width="1920" height="1080">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#1a1a2e"/>
      <stop offset="50%" style="stop-color:#16213e"/>
      <stop offset="100%" style="stop-color:#0f3460"/>
    </linearGradient>
  </defs>
  <rect width="1920" height="1080" fill="url(#bg)"/>
  <text x="960" y="520" font-family="sans-serif" font-size="72" fill="#e94560" text-anchor="middle" font-weight="bold">nemOS</text>
  <text x="960" y="580" font-family="sans-serif" font-size="24" fill="#a0a0a0" text-anchor="middle">Système d'exploitation Linux</text>
</svg>
SVG
    fi

    # Configurer nitrogen (sélecteur de fond d'écran)
    mkdir -p /etc/nitrogen
    cat > /etc/nitrogen/nitrogen.cfg <<EOF
[nitrogen]
view=icon
recurse=false
sort=alpha
icon_caps=false
dirs=/usr/share/backgrounds/nemos-wallpapers;
EOF

    cat > /etc/nitrogen/bg-saved.cfg <<EOF
[xin_0]
file=/usr/share/backgrounds/nemos-wallpapers/nemos-default.svg
mode=0
bgcolor=#000000
EOF

    # Créer le fichier de version
    cat > "${NEMOS_ASSETS_DIR}/version" <<EOF
nemOS ${NEMOS_VERSION}
Construit le $(date -u +%Y-%m-%d)
Noyau : $(uname -r 2>/dev/null || echo "inconnu")
Architecture : $(uname -m 2>/dev/null || echo "inconnue")
EOF

    # Copier les ressources vers l'utilisateur par défaut si le répertoire existe
    if [[ -d "/home/${NEMOS_DEFAULT_USER}" ]]; then
        mkdir -p "/home/${NEMOS_DEFAULT_USER}/Images"
        cp -r /usr/share/backgrounds/nemos-wallpapers \
              "/home/${NEMOS_DEFAULT_USER}/Images/" 2>/dev/null || true
        chown -R "${NEMOS_DEFAULT_USER}:${NEMOS_DEFAULT_USER}" \
              "/home/${NEMOS_DEFAULT_USER}/Images" 2>/dev/null || true
    fi

    msg_ok "Ressources visuelles nemOS installées."
}

# ============================================================================
# optimize_system() - Nettoyage et optimisation du système
#
# Appelle le script de nettoyage s'il est disponible, sinon effectue
# un nettoyage minimal directement.
# ============================================================================
optimize_system() {
    msg_info "Optimisation du système..."

    # Vérifier si le script de nettoyage est disponible
    local cleanup_script="/usr/local/bin/nemos-cleanup"
    if [[ -x "${cleanup_script}" ]]; then
        msg_info "Exécution du script de nettoyage dédié..."
        "${cleanup_script}" || msg_warn "Le script de nettoyage a retourné une erreur."
    else
        msg_info "Script de nettoyage dédié introuvable, nettoyage minimal..."

        # Nettoyage minimal en ligne
        msg_info "Vidage du cache pacman..."
        rm -rf /var/cache/pacman/pkg/* 2>/dev/null || true

        msg_info "Suppression des fichiers temporaires..."
        rm -rf /tmp/* /var/tmp/* 2>/dev/null || true

        msg_info "Suppression des journaux..."
        rm -f /var/log/*.log 2>/dev/null || true
        rm -rf /var/log/journal/* 2>/dev/null || true

        msg_info "Suppression des symboles de débogage..."
        find /usr -type f -executable -exec strip --strip-all {} + 2>/dev/null || true

        msg_info "Compression des pages de manuel..."
        find /usr/share/man -type f -name '*.[1-9]' -exec gzip -9 -f {} \; 2>/dev/null || true

        msg_info "Mise à zéro de l'espace libre..."
        dd if=/dev/zero of=/tmp/zero bs=1M status=none 2>/dev/null || true
        rm -f /tmp/zero
        sync
    fi

    msg_ok "Optimisation du système terminée."
}

# ============================================================================
# Fonction principale — appelle toutes les fonctions dans l'ordre
# ============================================================================
nemos_chroot_build_all() {
    msg_info "Début de la construction nemOS dans le chroot..."
    echo ""

    configure_locale
    configure_timezone
    configure_hostname
    create_user
    install_nemos_assets
    configure_display
    enable_services
    optimize_system

    echo ""
    msg_info "Construction dans le chroot terminée avec succès !"
    msg_info "Résumé :"
    msg_info "  - Locale       : ${NEMOS_LOCALE}"
    msg_info "  - Fuseau horaire : ${NEMOS_TIMEZONE}"
    msg_info "  - Nom d'hôte    : ${NEMOS_HOSTNAME}"
    msg_info "  - Utilisateur   : ${NEMOS_DEFAULT_USER}"
    msg_info "  - Affichage     : ${NEMOS_DISPLAY_MANAGER} + ${NEMOS_SESSION}"
}

# Si ce script est exécuté directement (pas sourcé), lancer tout
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    case "${1:-all}" in
        locale)       configure_locale ;;
        timezone)     configure_timezone ;;
        hostname)     configure_hostname ;;
        user)         create_user ;;
        display)      configure_display ;;
        assets)       install_nemos_assets ;;
        services)     enable_services ;;
        optimize)     optimize_system ;;
        all|*)        nemos_chroot_build_all ;;
    esac
fi