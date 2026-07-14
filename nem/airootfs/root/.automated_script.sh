#!/usr/bin/env bash
# ============================================================================
# nemOS - Script de configuration automatique de la session live
#
# Ce script est exécuté automatiquement lors du démarrage de l'ISO live.
# Il configure l'environnement de la session live pour que l'utilisateur
# puisse immédiatement tester nemOS ou lancer l'installateur Calamares.
#
# Fichier : /root/.automated_script.sh (convention archiso)
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Variables
# ---------------------------------------------------------------------------
LIVE_USER="nemos"
NEMOS_VERSION="1.0"

# Couurs
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Fonctions
# ---------------------------------------------------------------------------

msg() { echo -e "${CYAN}[nemOS live]${NC} $1"; }

# ============================================================================
# Étape 1 : Définir le mot de passe root pour la session live
#
# En session live, le mot de passe root est « nemOS » pour permettre
# les opérations d'administration pendant le test.
# ============================================================================
set_root_password() {
    msg "Configuration du mot de passe root pour la session live..."
    echo "root:nemOS" | chpasswd 2>/dev/null || true
    msg "Mot de passe root défini sur 'nemOS' (session live uniquement)."
}

# ============================================================================
# Étape 2 : Configurer NetworkManager pour la session live
#
# Active et démarre NetworkManager pour que l'utilisateur puisse
# se connecter au réseau Wi-Fi ou filaire dès le démarrage.
# ============================================================================
configure_network_live() {
    msg "Configuration du réseau pour la session live..."

    # Activer NetworkManager
    if systemctl enable NetworkManager 2>/dev/null; then
        msg "NetworkManager activé au démarrage."
    fi

    # Démarrer NetworkManager immédiatement
    if systemctl start NetworkManager 2>/dev/null; then
        msg "NetworkManager démarré avec succès."
    else
        msg "NetworkManager est peut-être déjà en cours d'exécution."
    fi

    # Désactiver le service systemd-networkd s'il est actif (conflit possible)
    if systemctl is-active systemd-networkd &>/dev/null; then
        systemctl stop systemd-networkd 2>/dev/null || true
        systemctl disable systemd-networkd 2>/dev/null || true
        msg "systemd-networkd désactivé au profit de NetworkManager."
    fi

    # Activer le Wi-Fi si une interface est présente
    rfkill unblock all 2>/dev/null || true
}

# ============================================================================
# Étape 3 : Démarrer les services essentiels pour la session live
# ============================================================================
start_live_services() {
    msg "Démarrage des services essentiels..."

    # Liste des services à démarrer en session live
    local services=(
        "dbus"              # Bus de messages système
        "bluetooth"         # Support Bluetooth
        "cups"              # Système d'impression
        "haveged"           # Générateur d'entropie
        "systemd-timesyncd" # Synchronisation de l'heure
    )

    for svc in "${services[@]}"; do
        # Démarrer le service s'il existe (sans échouer s'il n'est pas installé)
        if systemctl list-unit-files "${svc}.service" &>/dev/null; then
            systemctl start "${svc}" 2>/dev/null && \
                msg "  Service '${svc}' démarré." || \
                msg "  Service '${svc}' : échec du démarrage (pas critique)."
        fi
    done

    # Configurer le pare-feu pour la session live (plus permissif)
    if command -v nft &>/dev/null; then
        # En session live, on ne bloque pas le trafic entrant
        msg "  Pare-feu configuré en mode permissif (session live)."
    fi
}

# ============================================================================
# Étape 4 : Afficher le message de bienvenue
# ============================================================================
show_welcome_message() {
    clear

    echo -e "${GREEN}${BOLD}"
    cat <<'LOGO'
    _  _   __   ___  _  _  ____  ____  _  _  ____  _  _  ____  ____
   / )( \ / _\ / __)/ )( \( ___)/ ___)/ )( \(  _ \( \/ )(  _ \(  __\
   ) __ (/    ( (__ ) \/ ( )__) \___ \) \/ ( )   / )  (  )   / ) _)
   \_)(_/ \_/\_/\___)\____/(____)(____/ \____/(__\_)(_/\_)(____)(____)
LOGO
    echo -e "${NC}"

    echo -e "${BOLD}           ╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}           ║     Bienvenue dans la session live nemOS      ║${NC}"
    echo -e "${BOLD}           ╚═══════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "  ${DIM}Version ${NEMOS_VERSION} — Session live (aucune modification du disque)${NC}"
    echo ""
    echo -e "  ${YELLOW}Informations de la session live :${NC}"
    echo ""
    echo -e "    ${BOLD}Utilisateur root${NC}  mot de passe : ${BOLD}nemOS${NC}"
    echo -e "    ${BOLD}Utilisateur live${NC} mot de passe : ${BOLD}nemOS${NC}"
    echo ""
    echo -e "  ${YELLOW}Actions disponibles :${NC}"
    echo ""
    echo -e "    ${CYAN}1.${NC} ${BOLD}Installer nemOS${NC}       Double-cliquez sur l'icône"
    echo -e "                              « Installer nemOS » du bureau"
    echo -e "                              ou lancez : ${DIM}sudo calamares${NC}"
    echo ""
    echo -e "    ${CYAN}2.${NC} ${BOLD}Tester le système${NC}      Explorez librement, connectez-vous"
    echo -e "                              au Wi-Fi, testez les applications."
    echo ""
    echo -e "    ${CYAN}3.${NC} ${BOLD}Ouvrir un terminal${NC}    Menu → Accessoires → Terminal"
    echo -e "                              ou ${DIM}Ctrl+Alt+T${NC}"
    echo ""
    echo -e "  ${DIM}La session live est en RAM — redémarrez pour annuler tout changement.${NC}"
    echo ""
}

# ============================================================================
# Étape 5 : Configurer l'utilisateur de la session live
#
# Crée (ou configure) un utilisateur « nemos » pour la session live.
# ============================================================================
configure_live_user() {
    msg "Configuration de l'utilisateur live..."

    # Vérifier si l'utilisateur live existe déjà (créé par archiso)
    if id "${LIVE_USER}" &>/dev/null; then
        msg "Utilisateur '${LIVE_USER}' déjà existant."
    else
        # Créer l'utilisateur live
        useradd -m -G users,audio,video,power,storage,input,lp,network \
                -s /bin/bash -c "Utilisateur live nemOS" "${LIVE_USER}" 2>/dev/null || true
    fi

    # Définir le mot de passe de l'utilisateur live
    echo "${LIVE_USER}:nemOS" | chpasswd 2>/dev/null || true

    # Configurer sudo pour l'utilisateur live (sans mot de passe)
    mkdir -p /etc/sudoers.d
    cat > /etc/sudoers.d/nemos-live <<EOF
# Configuration sudo pour la session live nemOS
# L'utilisateur live a un accès sudo sans mot de passe
${LIVE_USER} ALL=(ALL) NOPASSWD: ALL
EOF
    chmod 0440 /etc/sudoers.d/nemos-live

    msg "Utilisateur live '${LIVE_USER}' configuré (mot de passe : nemOS)."
}

# ============================================================================
# Étape 6 : Préparer l'installateur Calamares
#
# Vérifie que Calamares est installé et crée les raccourcis nécessaires
# sur le bureau de l'utilisateur live.
# ============================================================================
prepare_installer() {
    msg "Préparation de l'installateur Calamares..."

    local user_home
    user_home="$(eval echo "~${LIVE_USER}" 2>/dev/null || echo "/home/${LIVE_USER}")"
    local desktop_dir="${user_home}/Bureau"
    local desktop_dir_fr="${user_home}/Desktop"

    # Créer les deux répertoires (Bureau et Desktop) pour compatibilité
    mkdir -p "${desktop_dir}" "${desktop_dir_fr}"

    # Créer le raccourci de l'installateur sur le bureau
    if command -v calamares &>/dev/null; then
        cat > "${desktop_dir}/installer-nemOS.desktop" <<DESKTOP
[Desktop Entry]
Type=Application
Name=Installer nemOS
Name[fr]=Installer nemOS
Comment=Installer nemOS sur votre ordinateur
Comment[fr]=Installer nemOS sur votre ordinateur
Exec=sudo -E calamares
Icon=system-software-install
Terminal=false
StartupNotify=true
Categories=System;
Keywords=install;system;nemOS;
DESKTOP

        # Copier aussi dans Desktop (anglais)
        cp "${desktop_dir}/installer-nemOS.desktop" "${desktop_dir_fr}/" 2>/dev/null || true

        # Rendre les raccourcis exécutables
        chmod +x "${desktop_dir}/installer-nemOS.desktop" 2>/dev/null || true
        chmod +x "${desktop_dir_fr}/installer-nemOS.desktop" 2>/dev/null || true

        # S'assurer que les fichiers appartiennent à l'utilisateur live
        chown -R "${LIVE_USER}:${LIVE_USER}" "${desktop_dir}" "${desktop_dir_fr}" 2>/dev/null || true

        msg "Raccourci d'installation créé sur le bureau."
    else
        msg "Calamares n'est pas installé. L'installateur ne sera pas disponible."
        msg "Pour l'ajouter au profil, ajoutez 'calamares' à packages.x86_64."
    fi

    # Créer le fichier de configuration Calamares s'il n'existe pas
    if [[ ! -f /etc/calamares/settings.conf ]] && command -v calamares &>/dev/null; then
        mkdir -p /etc/calamares
        cat > /etc/calamares/settings.conf <<CALAMARES
# Configuration Calamares pour nemOS
---
# Chemin vers les modules
modules-search: [ local ]

# Séquence d'installation
sequence:
  - show:
    - welcome
    - locale
    - keyboard
    - partition
    - users
    - summary
  - exec:
    - partition
    - mount
    - unpackfs
    - machineid
    - fstab
    - locale
    - keyboard
    - localecfg
    - users
    - displaymanager
    - networkcfg
    - hwclock
    - services
    - packages
    - initramfs
    - grubcfg
    - bootloader
    - postcfg
    - umount
  - show:
    - finished

# Chemins de branding
branding: nemOS

# Configuration du prompt
prompt-install: false
CALAMARES
        msg "Configuration Calamares par défaut créée."
    fi
}

# ============================================================================
# Étape 7 : Configurer l'interface graphique de la session live
# ============================================================================
configure_live_display() {
    msg "Configuration de l'affichage de la session live..."

    # S'assurer que le gestionnaire de connexion est prêt
    if command -v lightdm &>/dev/null; then
        # Démarrer lightdm s'il n'est pas déjà actif
        if ! systemctl is-active --quiet lightdm 2>/dev/null; then
            systemctl start lightdm 2>/dev/null || true
        fi
    fi

    # Configurer le fond d'écran de la session live
    if [[ -f /usr/share/backgrounds/nemos-wallpapers/nemos-default.svg ]]; then
        # Configurer nitrogen avec le fond d'écran par défaut
        mkdir -p "/home/${LIVE_USER}/.config/nitrogen"
        cat > "/home/${LIVE_USER}/.config/nitrogen/bg-saved.cfg" <<EOF
[xin_0]
file=/usr/share/backgrounds/nemos-wallpapers/nemos-default.svg
mode=0
bgcolor=#000000
EOF
        chown -R "${LIVE_USER}:${LIVE_USER}" "/home/${LIVE_USER}/.config" 2>/dev/null || true
    fi
}

# ============================================================================
# Point d'entrée principal
#
# Ce script est exécuté automatiquement par archiso au démarrage de la
# session live. Il ne doit PAS être interactif — toute la configuration
# est automatique.
# ============================================================================
main() {
    # Journalisation de la session live
    exec > >(tee -a "/var/log/nemos-live-setup.log") 2>&1

    msg "=== Début de la configuration automatique de la session live ==="
    msg "Date : $(date)"
    msg "Noyau : $(uname -r)"

    # Exécuter toutes les étapes de configuration
    set_root_password
    configure_live_user
    configure_network_live
    start_live_services
    prepare_installer
    configure_live_display
    show_welcome_message

    msg "=== Configuration automatique de la session live terminée ==="
}

# Exécution
main "$@"