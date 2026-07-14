#!/usr/bin/env bash
# ============================================================================
# nemOS - Script de configuration au premier démarrage
# Exécuté lors de la première connexion après l'installation
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Variables globales
# ---------------------------------------------------------------------------
NEMOS_VERSION="1.0"
NEMOS_WALLPAPER_DIR="/usr/share/backgrounds/nemos-wallpapers"
USER_HOME=""
USERNAME=""
FULLNAME="Utilisateur nemOS"

# Couurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------------

msg_info()  { echo -e "${BLUE}[INFO]${NC} $1"; }
msg_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
msg_warn()  { echo -e "${YELLOW}[! ]${NC} $1"; }
msg_err()   { echo -e "${RED}[ERR]${NC} $1" >&2; }
msg_step()  { echo -e "\n${BOLD}${CYAN}--- $1 ---${NC}\n"; }

# Demander une entrée utilisateur avec une valeur par défaut
ask() {
    local prompt="$1"
    local default="${2:-}"
    local response

    if [[ -n "${default}" ]]; then
        echo -en "${BOLD}${prompt}${NC} [${DIM}${default}${NC}]: "
    else
        echo -en "${BOLD}${prompt}${NC}: "
    fi

    read -r response
    if [[ -z "${response}" && -n "${default}" ]]; then
        echo "${default}"
    else
        echo "${response}"
    fi
}

# Demander une confirmation oui/non
ask_yes_no() {
    local prompt="$1"
    local default="${2:-o}"
    local response

    case "${default}" in
        o|O|oui|OUI) echo -en "${BOLD}${prompt}${NC} [${DIM}O/n${NC}]: " ;;
        *)            echo -en "${BOLD}${prompt}${NC} [${DIM}o/N${NC}]: " ;;
    esac

    read -r response
    case "${response}" in
        o|O|oui|OUI|y|Y|yes|YES|"") [[ "${default}" =~ ^[oOyY] ]] && return 0 || return 1 ;;
        *) return 1 ;;
    esac
}

# ---------------------------------------------------------------------------
# Logo ASCII art nemOS
# ---------------------------------------------------------------------------
show_welcome() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat <<'LOGO'
    _  _   __   ___  _  _  ____  ____  _  _  ____  _  _  ____  ____
   / )( \ / _\ / __)/ )( \( ___)/ ___)/ )( \(  _ \( \/ )(  _ \(  __\
   ) __ (/    ( (__ ) \/ ( )__) \___ \) \/ ( )   / )  (  )   / ) _)
   \_)(_/ \_/\_/\___)\____/(____)(____/ \____/(__\_)(_/\_)(____)(____)
LOGO
    echo -e "${NC}"
    echo -e "${BOLD}              Bienvenue dans nemOS ${NEMOS_VERSION}${NC}"
    echo -e "${DIM}     Système d'exploitation Linux léger et élégant${NC}"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  Configuration initiale du système                         ║${NC}"
    echo -e "${YELLOW}║  Ce guide vous aidera à configurer votre nouveau système.  ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${DIM}Appuyez sur Entrée pour commencer la configuration...${NC}"
    read -r
}

# ---------------------------------------------------------------------------
# Configuration du nom d'hôte
# ---------------------------------------------------------------------------
configure_hostname() {
    msg_step "Configuration du nom d'hôte"

    local current_hostname
    current_hostname="$(hostname 2>/dev/null || echo "")"

    local new_hostname
    new_hostname="$(ask "Entrez le nom de cet ordinateur" "${current_hostname:-nemOS-pc}")"

    # Sanitiser le nom d'hôte (remplacer les espaces et caractères spéciaux)
    new_hostname="$(echo "${new_hostname}" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
    new_hostname="${new_hostname:-nemOS-pc}"

    if hostnamectl set-hostname "${new_hostname}" 2>/dev/null; then
        # Mettre aussi à jour /etc/hosts
        if ! grep -q "127.0.1.1.*${new_hostname}" /etc/hosts 2>/dev/null; then
            echo "127.0.1.1	${new_hostname}" >> /etc/hosts
        fi
        msg_ok "Nom d'hôte défini sur : ${new_hostname}"
    else
        msg_warn "Impossible de définir le nom d'hôte avec hostnamectl."
        echo "${new_hostname}" > /etc/hostname
        msg_ok "Nom d'hôte écrit dans /etc/hostname : ${new_hostname}"
    fi
}

# ---------------------------------------------------------------------------
# Configuration de NetworkManager
# ---------------------------------------------------------------------------
configure_network() {
    msg_step "Configuration du réseau"

    # Activer NetworkManager au démarrage
    if systemctl enable NetworkManager 2>/dev/null; then
        msg_ok "NetworkManager activé au démarrage."
    else
        msg_warn "Impossible d'activer NetworkManager."
    fi

    # Démarrer NetworkManager immédiatement si ce n'est pas déjà fait
    if ! systemctl is-active --quiet NetworkManager 2>/dev/null; then
        systemctl start NetworkManager 2>/dev/null && \
            msg_ok "NetworkManager démarré." || \
            msg_warn "Impossible de démarrer NetworkManager maintenant."
    else
        msg_ok "NetworkManager est déjà en cours d'exécution."
    fi

    echo ""
    msg_info "Réseaux Wi-Fi détectés :"
    if nmcli -t -f SSID,SECURITY device wifi list 2>/dev/null | head -10; then
        echo ""
    else
        msg_warn "Aucune interface Wi-Fi détectée ou nmcli indisponible."
    fi
}

# ---------------------------------------------------------------------------
# Configuration de la locale française
# ---------------------------------------------------------------------------
configure_locale() {
    msg_step "Configuration de la locale"

    # Vérifier si la locale française est déjà configurée
    if locale | grep -q "LANG=fr_FR"; then
        msg_ok "La locale française est déjà configurée."
        return
    fi

    # Décommenter fr_FR.UTF-8 dans locale.gen si nécessaire
    if [[ -f /etc/locale.gen ]]; then
        if ! grep -q "^fr_FR.UTF-8" /etc/locale.gen; then
            sed -i 's/#fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen
        fi
        if ! grep -q "^en_US.UTF-8" /etc/locale.gen; then
            sed -i 's/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
        fi
        locale-gen 2>/dev/null || true
    fi

    # Définir la locale par défaut
    if [[ -f /etc/locale.conf ]]; then
        echo "LANG=fr_FR.UTF-8" > /etc/locale.conf
        echo "LANGUAGE=fr:en" >> /etc/locale.conf
    fi

    # Configurer les variables de clé console si applicable
    if [[ -f /etc/vconsole.conf ]]; then
        echo "KEYMAP=fr-latin9" > /etc/vconsole.conf
        echo "FONT=lat0-16" >> /etc/vconsole.conf
    fi

    export LANG=fr_FR.UTF-8
    msg_ok "Locale française configurée."
}

# ---------------------------------------------------------------------------
# Génération du fichier fstab
# ---------------------------------------------------------------------------
generate_fstab() {
    msg_step "Vérification du fichier fstab"

    if [[ ! -f /etc/fstab ]] || [[ ! -s /etc/fstab ]]; then
        msg_warn "Le fichier /etc/fstab est vide ou absent. Génération..."
        # Tentative de génération avec genfstab (si disponible)
        if command -v genfstab &>/dev/null; then
            genfstab -U / > /etc/fstab 2>/dev/null && \
                msg_ok "fstab généré avec genfstab." || \
                msg_err "Échec de genfstab."
        else
            msg_warn "genfstab n'est pas disponible. Ajout des entrées minimales."
            cat >> /etc/fstab <<'FSTAB'

# /etc/fstab: informations sur les systèmes de fichiers statiques
# <système de fichiers>  <point de montage>  <type>  <options>  <dump>  <pass>
tmpfs                   /tmp                tmpfs   defaults,nosuid,nodev  0  0
FSTAB
            msg_ok "Entrées minimales ajoutées au fstab."
        fi
    else
        msg_ok "Le fichier fstab existe et n'est pas vide."
    fi
}

# ---------------------------------------------------------------------------
# Activation du TRIM pour les SSD
# ---------------------------------------------------------------------------
enable_trim() {
    msg_step "Vérification du support TRIM (SSD)"

    # Vérifier si le disque racine supporte le TRIM
    local root_disk
    root_disk="$(findmnt -n -o SOURCE / 2>/dev/null | head -n1)"

    if [[ -z "${root_disk}" ]]; then
        msg_warn "Impossible de déterminer le disque racine."
        return
    fi

    # Vérifier si c'est un SSD (vérification via /sys/block)
    local block_dev
    block_dev="$(echo "${root_disk}" | sed 's/[0-9]*$//' | sed 's/p[0-9]*$//')"
    block_dev="$(basename "${block_dev}")"

    local is_ssd=false
    if [[ -f "/sys/block/${block_dev}/queue/rotational" ]]; then
        local rotational
        rotational="$(cat "/sys/block/${block_dev}/queue/rotational" 2>/dev/null || echo 1)"
        if [[ "${rotational}" == "0" ]]; then
            is_ssd=true
        fi
    fi

    if [[ "${is_ssd}" == true ]]; then
        msg_info "SSD détecté (${block_dev}). Activation du TRIM..."

        # Activer fstrim.timer pour le TRIM périodique
        if systemctl enable fstrim.timer 2>/dev/null; then
            msg_ok "Service fstrim.timer activé (TRIM hebdomadaire)."
        else
            msg_warn "Impossible d'activer fstrim.timer."
        fi

        # Essayer un TRIM immédiat
        if fstrim -v / 2>/dev/null; then
            msg_ok "TRIM effectué avec succès."
        else
            msg_warn "Le TRIM immédiat a échoué (normal pour certains disques virtuels)."
        fi
    else
        msg_info "Disque rotatif détecté (${block_dev}). TRIM non nécessaire."
    fi
}

# ---------------------------------------------------------------------------
# Création du compte utilisateur
# ---------------------------------------------------------------------------
configure_user() {
    msg_step "Configuration du compte utilisateur"

    # Demander le nom d'utilisateur
    local default_user="nem"
    USERNAME="$(ask "Entrez le nom d'utilisateur" "${default_user}")"

    # Sanitiser le nom d'utilisateur
    USERNAME="$(echo "${USERNAME}" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')"
    USERNAME="${USERNAME:-nem}"

    FULLNAME="$(ask "Entrez le nom complet" "Utilisateur nemOS")"

    # Vérifier si l'utilisateur existe déjà
    if id "${USERNAME}" &>/dev/null; then
        msg_info "L'utilisateur '${USERNAME}' existe déjà."
        USER_HOME="$(eval echo "~${USERNAME}")"
        msg_ok "Répertoire personnel : ${USER_HOME}"
    else
        msg_info "Création de l'utilisateur '${USERNAME}'..."

        # Créer l'utilisateur
        useradd -m -c "${FULLNAME}" -s /bin/bash "${USERNAME}" 2>/dev/null || \
        useradd -m -G users,audio,video,power,storage -s /bin/bash "${USERNAME}" 2>/dev/null

        # Définir le mot de passe
        echo ""
        msg_info "Définissez le mot de passe pour '${USERNAME}':"
        passwd "${USERNAME}"

        USER_HOME="$(eval echo "~${USERNAME}")"
        msg_ok "Utilisateur '${USERNAME}' créé avec succès."
    fi

    # Configurer sudo
    msg_info "Configuration de sudo pour '${USERNAME}'..."

    # Ajouter l'utilisateur aux groupes pertinents
    for group in wheel audio video power storage input lp network; do
        if getent group "${group}" &>/dev/null; then
            usermod -aG "${group}" "${USERNAME}" 2>/dev/null || true
        fi
    done

    # Configurer sudoers
    local sudoers_file="/etc/sudoers.d/nemos-user"
    cat > "${sudoers_file}" <<SUDOERS
# Configuration sudo pour l'utilisateur nemOS
# Fichier : ${sudoers_file}
${USERNAME} ALL=(ALL) ALL
# Conserver les variables d'environnement pour les applications graphiques
Defaults env_keep += "DISPLAY XAUTHORITY"
SUDOERS
    chmod 0440 "${sudoers_file}"

    msg_ok "Sudo configuré pour '${USERNAME}'."
}

# ---------------------------------------------------------------------------
# Activation des services essentiels
# ---------------------------------------------------------------------------
enable_services() {
    msg_step "Activation des services système"

    local services=(
        "NetworkManager"    # Gestion réseau
        "bluetooth"         # Bluetooth
        "cups"              # Impression
        "lightdm"           # Gestionnaire de connexion (si installé)
        "dbus"              # Bus système
        "cronie"            # Planificateur de tâches (si installé)
    )

    for svc in "${services[@]}"; do
        if systemctl list-unit-files "${svc}.service" &>/dev/null; then
            if systemctl enable "${svc}" 2>/dev/null; then
                msg_ok "Service '${svc}' activé."
            else
                msg_warn "Impossible d'activer le service '${svc}'."
            fi
        else
            msg_info "Service '${svc}' non installé, ignoré."
        fi
    done
}

# ---------------------------------------------------------------------------
# Application du thème nemOS
# ---------------------------------------------------------------------------
apply_nemos_theme() {
    msg_step "Application du thème nemOS"

    if [[ -z "${USER_HOME}" || ! -d "${USER_HOME}" ]]; then
        msg_warn "Répertoire personnel de l'utilisateur introuvable."
        return
    fi

    # Configurer le thème GTK si les fichiers existent
    local themes_dir="/usr/share/themes"
    local icons_dir="/usr/share/icons"

    # Créer les répertoires de configuration si nécessaire
    mkdir -p "${USER_HOME}/.config/gtk-3.0"
    mkdir -p "${USER_HOME}/.config/gtk-4.0"
    mkdir -p "${USER_HOME}/.config/openbox"

    # Configuration GTK 3
    if [[ -d "${themes_dir}/nemOS" ]] || [[ -d "${themes_dir}/Adwaita-dark" ]]; then
        local gtk_theme="nemOS"
        if [[ ! -d "${themes_dir}/nemOS" ]]; then
            gtk_theme="Adwaita-dark"
        fi

        cat > "${USER_HOME}/.config/gtk-3.0/settings.ini" <<GTK3INI
[Settings]
gtk-theme-name=${gtk_theme}
gtk-icon-theme-name=nemOS-icons
gtk-font-name=Sans 10
gtk-cursor-theme-name=Adwaita
gtk-application-prefer-dark-theme=1
GTK3INI

        # Copier pour GTK 4
        cp "${USER_HOME}/.config/gtk-3.0/settings.ini" \
           "${USER_HOME}/.config/gtk-4.0/settings.ini" 2>/dev/null || true

        msg_ok "Thème GTK configuré : ${gtk_theme}."
    else
        msg_warn "Aucun thème nemOS trouvé dans ${themes_dir}."
    fi

    # Configuration Openbox
    cat > "${USER_HOME}/.config/openbox/rc.xml" <<'OPENBOX_RC'
<?xml version="1.0" encoding="UTF-8"?>
<openbox_config xmlns="http://openbox.org/3.4/rc">
  <resistance>
    <strength>10</strength>
    <window_strength>10</window_strength>
  </resistance>
  <focus>
    <focusNew>yes</focusNew>
    <followMouse>no</followMouse>
  </focus>
  <theme>
    <name>nemOS</name>
    <titleLayout>NLIMC</titleLayout>
    <keepBorder>yes</keepBorder>
    <animateIconify>yes</animateIconify>
  </theme>
  <desktops>
    <number>4</number>
    <firstdesk>1</firstdesk>
  </desktops>
  <keyboard>
    <chainQuitKey>C-g</chainQuitKey>
    <keybind key="A-F2">
      <action name="Execute">
        <command>rofi -show run</command>
      </action>
    </keybind>
    <keybind key="A-F4">
      <action name="Close"/>
    </keybind>
    <keybind key="C-A-Left">
      <action name="DesktopLeft">
        <wrap>yes</wrap>
      </action>
    </keybind>
    <keybind key="C-A-Right">
      <action name="DesktopRight">
        <wrap>yes</wrap>
      </action>
    </keybind>
  </keyboard>
  <applications/>
</openbox_config>
OPENBOX_RC

    msg_ok "Configuration OpenBox créée."
}

# ---------------------------------------------------------------------------
# Copie des fonds d'écran nemOS
# ---------------------------------------------------------------------------
copy_wallpapers() {
    msg_step "Installation des fonds d'écran"

    if [[ -z "${USER_HOME}" || ! -d "${USER_HOME}" ]]; then
        msg_warn "Répertoire personnel de l'utilisateur introuvable."
        return
    fi

    mkdir -p "${USER_HOME}/Images/nemOS-wallpapers"

    if [[ -d "${NEMOS_WALLPAPER_DIR}" ]]; then
        # Copier les fonds d'écran
        cp -r "${NEMOS_WALLPAPER_DIR}"/* "${USER_HOME}/Images/nemOS-wallpapers/" 2>/dev/null || true
        local count
        count="$(find "${USER_HOME}/Images/nemOS-wallpapers" -type f 2>/dev/null | wc -l)"
        msg_ok "${count} fonds d'écran copiés vers ~/Images/nemOS-wallpapers/"
    else
        msg_warn "Répertoire des fonds d'écran introuvable : ${NEMOS_WALLPAPER_DIR}"
        msg_info "Création du répertoire ~/Images/nemOS-wallpapers/ (vide)."
    fi

    # Définir les permissions correctes
    chown -R "${USERNAME}:${USERNAME}" "${USER_HOME}/Images" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# Proposition d'installation de Flatpak
# ---------------------------------------------------------------------------
ask_flatpak() {
    msg_step "Support Flatpak"

    if ask_yes_no "Voulez-vous installer le support Flatpak ?" "o"; then
        if command -v pacman &>/dev/null; then
            msg_info "Installation de flatpak..."
            pacman -S --noconfirm flatpak 2>/dev/null && \
                msg_ok "Flatpak installé." || \
                msg_err "Échec de l'installation de Flatpak."

            # Ajouter le dépôt Flathub
            if command -v flatpak &>/dev/null; then
                msg_info "Ajout du dépôt Flathub..."
                su - "${USERNAME}" -c "flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo" 2>/dev/null && \
                    msg_ok "Dépôt Flathub ajouté." || \
                    msg_warn "Impossible d'ajouter Flathub."
            fi
        else
            msg_warn "pacman n'est pas disponible. Installez Flatpak manuellement."
        fi
    else
        msg_info "Flatpak non installé. Vous pourrez l'ajouter plus tard avec :"
        echo "  sudo pacman -S flatpak && flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo"
    fi
}

# ---------------------------------------------------------------------------
# Message final avec commandes utiles
# ---------------------------------------------------------------------------
show_final_message() {
    clear
    echo -e "${GREEN}${BOLD}"
    cat <<'FINAL'
    _  _   __   ___  _  _  ____  ____  _  _  ____  _  _  ____  ____
   / )( \ / _\ / __)/ )( \( ___)/ ___)/ )( \(  _ \( \/ )(  _ \(  __\
   ) __ (/    ( (__ ) \/ ( )__) \___ \) \/ ( )   / )  (  )   / ) _)
   \_)(_/ \_/\_/\___)\____/(____)(____/ \____/(__\_)(_/\_)(____)(____)
FINAL
    echo -e "${NC}"
    echo -e "${BOLD}              Configuration terminée !${NC}"
    echo ""
    echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║             Votre système nemOS est prêt !                 ║${NC}"
    echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BOLD}  Commandes utiles :${NC}"
    echo ""
    echo -e "  ${CYAN}Gestion des paquets :${NC}"
    echo -e "    sudo pacman -Syu              Mettre à jour le système"
    echo -e "    sudo pacman -S <paquet>       Installer un paquet"
    echo -e "    sudo pacman -Rs <paquet>      Supprimer un paquet"
    echo ""
    echo -e "  ${CYAN}Réseau :${NC}"
    echo -e "    nmtui                          Gérer le réseau (interface texte)"
    echo -e "    nmcli dev wifi list            Lister les réseaux Wi-Fi"
    echo -e "    nmcli dev wifi connect <SSID>  Se connecter à un réseau Wi-Fi"
    echo ""
    echo -e "  ${CYAN}Flatpak (si installé) :${NC}"
    echo -e "    flatpak update                 Mettre à jour les applications"
    echo -e "    flatpak install flathub <app>  Installer une application"
    echo ""
    echo -e "  ${CYAN}Services système :${NC}"
    echo -e "    sudo systemctl status <service>   Voir l'état d'un service"
    echo -e "    sudo systemctl enable <service>   Activer un service"
    echo -e "    nemos-services                    Gestionnaire de services nemOS"
    echo ""
    echo -e "  ${CYAN}Aide :${NC}"
    echo -e "    man <commande>                 Consulter le manuel"
    echo -e "    nemOS-help                     Aide spécifique à nemOS"
    echo ""
    echo -e "${DIM}  Pour signaler un bug ou contribuer : https://github.com/nemOS${NC}"
    echo ""
    echo -e "${GREEN}${BOLD}  Bonne découverte de nemOS ! 🇫🇷${NC}"
    echo ""
}

# ---------------------------------------------------------------------------
# Point d'entrée principal
# ---------------------------------------------------------------------------
main() {
    # Vérifier qu'on n'est pas root (ce script est pour l'utilisateur)
    if [[ "${EUID}" -eq 0 ]]; then
        echo -e "${YELLOW}Attention : ce script s'exécute en tant que root.${NC}"
        echo -e "${YELLOW}Certaines configurations s'appliqueront au niveau système.${NC}"
        echo ""
    fi

    # Séquence de configuration
    show_welcome
    configure_hostname
    configure_network
    configure_locale
    generate_fstab
    enable_trim
    configure_user
    enable_services
    apply_nemos_theme
    copy_wallpapers
    ask_flatpak
    show_final_message

    # Marquer la première configuration comme terminée
    touch /var/lib/nemos-firstboot-done 2>/dev/null || true
}

main "$@"