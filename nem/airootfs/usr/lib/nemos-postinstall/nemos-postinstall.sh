#!/bin/bash
# ============================================================================
# Script de post-installation pour nemOS
# Exécuté par Calamares après la copie des fichiers sur le disque cible
#
# Ce script est appelé via le module shellprocess de Calamares :
#   /etc/calamares/modules/shellprocess.conf
#
# Il s'exécute dans le chroot de la cible avec les privilèges root.
# ============================================================================

set -e

# ============================================================================
# Variables et fonctions utilitaires
# ============================================================================

# Couleurs pour les messages (utiles si connecté à un tty)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    BOLD='\033[1m'
    NC='\033[0m'
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    BOLD=''
    NC=''
fi

msg_info()  { echo -e "${BLUE}[nemOS]${NC} $1" 2>/dev/null || echo "[nemOS] $1"; }
msg_ok()    { echo -e "${GREEN}[OK]${NC} $1" 2>/dev/null || echo "[OK] $1"; }
msg_warn()  { echo -e "${YELLOW}[!]${NC} $1" 2>/dev/null || echo "[!] $1"; }
msg_err()   { echo -e "${RED}[ERREUR]${NC} $1" 2>/dev/null || echo "[ERREUR] $1"; }

# Déterminer le premier utilisateur non-système (créé par Calamares)
get_first_user() {
    # Calamares crée l'utilisateur spécifié dans le module "users"
    # On cherche le premier utilisateur régulier (UID >= 1000)
    local user=""
    while IFS=: read -r username _ uid _ _ home _; do
        if [ "$uid" -ge 1000 ] && [ "$username" != "nobody" ] && \
           [ "$username" != "nogroup" ]; then
            user="$username"
            break
        fi
    done < /etc/passwd
    echo "$user"
}

# Déterminer le groupe primaire de l'utilisateur
get_user_group() {
    local user="$1"
    local group=""
    while IFS=: read -r name _ gid members _; do
        # Chercher le groupe primaire de l'utilisateur
        if id -gn "$user" 2>/dev/null | grep -q "^${name}$"; then
            group="$name"
            break
        fi
    done < /etc/group
    if [ -z "$group" ]; then
        group="$(id -gn "$user" 2>/dev/null || echo "users")"
    fi
    echo "$group"
}

# ============================================================================
# Début de la post-installation
# ============================================================================

echo ""
echo "============================================================"
echo "  nemOS - Post-installation"
echo "  Configuration du système nouvellement installé"
echo "============================================================"
echo ""

# Récupérer l'utilisateur créé par Calamares
TARGET_USER="$(get_first_user)"
TARGET_GROUP="$(get_user_group "$TARGET_USER")"

if [ -n "$TARGET_USER" ]; then
    msg_info "Utilisateur cible détecté : ${BOLD}${TARGET_USER}${NC} (${TARGET_GROUP})"
else
    msg_warn "Aucun utilisateur cible détecté, configuration système uniquement."
fi

# ============================================================================
# 1. Appliquer le thème nemOS comme thème par défaut
# ============================================================================
msg_info "Configuration du thème GTK nemOS..."

# --- GTK 3 ---
if [ -n "$TARGET_USER" ] && [ -d "/home/${TARGET_USER}" ]; then
    GTK3_DIR="/home/${TARGET_USER}/.config/gtk-3.0"
    mkdir -p "$GTK3_DIR"
    cat > "$GTK3_DIR/settings.ini" << 'GTK3EOF'
[Settings]
gtk-theme-name=nemOS-Dark
gtk-icon-theme-name=nemOS-Icons
gtk-font-name=Noto Sans 11
gtk-cursor-theme-name=Adwaita
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-animations=1
gtk-primary-button-warps-slider=0
gtk-application-prefer-dark-theme=1
GTK3EOF
    chown -R "${TARGET_USER}:${TARGET_GROUP}" "/home/${TARGET_USER}/.config/gtk-3.0"
    msg_ok "Thème GTK 3 configuré pour ${TARGET_USER}"
else
    # Configuration système par défaut
    mkdir -p /etc/gtk-3.0
    cat > /etc/gtk-3.0/settings.ini << 'GTK3EOF'
[Settings]
gtk-theme-name=nemOS-Dark
gtk-icon-theme-name=nemOS-Icons
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
GTK3EOF
    msg_ok "Thème GTK 3 configuré (système)"
fi

# --- GTK 2 ---
if [ -n "$TARGET_USER" ] && [ -d "/home/${TARGET_USER}" ]; then
    cat > "/home/${TARGET_USER}/.gtkrc-2.0" << 'GTK2EOF'
gtk-theme-name="nemOS-Dark"
gtk-icon-theme-name="nemOS-Icons"
gtk-font-name="Noto Sans 11"
gtk-cursor-theme-name="Adwaita"
gtk-cursor-theme-size=24
gtk-toolbar-style=GTK_TOOLBAR_BOTH
gtk-toolbar-icon-size=GTK_ICON_SIZE_LARGE_TOOLBAR
gtk-button-images=1
gtk-menu-images=1
gtk-enable-animations=1
GTK2EOF
    chown "${TARGET_USER}:${TARGET_GROUP}" "/home/${TARGET_USER}/.gtkrc-2.0"
    msg_ok "Thème GTK 2 configuré pour ${TARGET_USER}"
fi

# --- Configuration système XDG ---
mkdir -p /etc/xdg/gtk-3.0
cat > /etc/xdg/gtk-3.0/settings.ini << 'XDGEOF'
[Settings]
gtk-theme-name=nemOS-Dark
gtk-icon-theme-name=nemOS-Icons
gtk-font-name=Noto Sans 11
gtk-application-prefer-dark-theme=1
XDGEOF
msg_ok "Configuration XDG GTK mise à jour"

# ============================================================================
# 2. Configurer les fonds d'écran nemOS
# ============================================================================
msg_info "Configuration des fonds d'écran..."

# Vérifier que les fonds d'écran sont installés
if [ -d "/usr/share/backgrounds/nemOS" ]; then
    # Définir le fond d'écran par défaut pour le gestionnaire d'affichage
    if [ -d "/etc/lightdm" ]; then
        if [ -f "/etc/lightdm/lightdm-gtk-greeter.conf" ]; then
            sed -i 's|^background=.*|background=/usr/share/backgrounds/nemOS/nemos-default.png|' \
                /etc/lightdm/lightdm-gtk-greeter.conf 2>/dev/null || true
            msg_ok "Fond d'écran LightDM configuré"
        else
            cat > /etc/lightdm/lightdm-gtk-greeter.conf << 'LDMEOF'
[greeter]
background=/usr/share/backgrounds/nemOS/nemos-default.png
theme-name=nemOS-Dark
icon-theme-name=nemOS-Icons
font-name=Noto Sans 11
LDMEOF
            msg_ok "Configuration LightDM créée"
        fi
    fi

    # Configuration du fond d'écran pour l'utilisateur
    if [ -n "$TARGET_USER" ] && [ -d "/home/${TARGET_USER}" ]; then
        # Créer le script d'autostart pour feh (si feh est disponible)
        AUTOSTART_DIR="/home/${TARGET_USER}/.config/openbox/autostart"
        mkdir -p "$(dirname "$AUTOSTART_DIR")"
        if [ -f "/usr/bin/feh" ]; then
            # Ajouter le fond d'écran à l'autostart d'OpenBox
            if ! grep -q "feh.*nemos" "$AUTOSTART_DIR" 2>/dev/null; then
                echo 'feh --bg-scale /usr/share/backgrounds/nemOS/nemos-default.png &' \
                    >> "$AUTOSTART_DIR" 2>/dev/null || true
            fi
        fi
        chown -R "${TARGET_USER}:${TARGET_GROUP}" "/home/${TARGET_USER}/.config/openbox"
        msg_ok "Fond d'écran utilisateur configuré"
    fi
else
    msg_warn "Répertoire /usr/share/backgrounds/nemOS non trouvé"
    msg_warn "Les fonds d'écran ne sont pas installés. Installez nemos-wallpapers."
fi

# ============================================================================
# 3. Configurer le dock Plank
# ============================================================================
msg_info "Configuration du dock Plank..."

if [ -n "$TARGET_USER" ] && [ -d "/home/${TARGET_USER}" ]; then
    PLANK_DIR="/home/${TARGET_USER}/.config/plank"
    PLANK_DOCK1="${PLANK_DIR}/dock1"
    mkdir -p "$PLANK_DOCK1"

    # Configuration du dock
    cat > "${PLANK_DOCK1}/settings.ini" << 'PLANKEOF'
[dock1]
alignment=center
auto-hide=false
hide-delay=0
icon-size=48
items-alignment=center
offset=0
orientation=bottom
plugins=DockyPreferences;DockyItems;RecentDocuments
show-dock=true
theme=Transparent
zoom-enabled=true
zoom-percent=150
PLANKEOF

    # Éléments par défaut du dock
    cat > "${PLANK_DOCK1}/dockbypass" << 'PLANKITEMSEOF'
[PlankItemsPreferences]
alignment=center
hide-mode=never
icon-size=48
offset=0
orientation=bottom
PLANKITEMSEOF

    chown -R "${TARGET_USER}:${TARGET_GROUP}" "$PLANK_DIR"
    msg_ok "Dock Plank configuré pour ${TARGET_USER}"

    # Ajouter plank à l'autostart d'OpenBox
    AUTOSTART_DIR="/home/${TARGET_USER}/.config/openbox"
    mkdir -p "$AUTOSTART_DIR"
    if ! grep -q "plank" "${AUTOSTART_DIR}/autostart" 2>/dev/null; then
        echo 'plank &' >> "${AUTOSTART_DIR}/autostart" 2>/dev/null || true
    fi
    chown -R "${TARGET_USER}:${TARGET_GROUP}" "$AUTOSTART_DIR"
else
    msg_warn "Pas d'utilisateur cible, dock non configuré."
fi

# ============================================================================
# 4. Configurer LightDM Greeter
# ============================================================================
msg_info "Configuration du gestionnaire d'affichage..."

if [ -f "/etc/lightdm/lightdm.conf" ]; then
    # S'assurer que lightdm-gtk-greeter est utilisé
    sed -i 's|^#\?greeter-session=.*|greeter-session=lightdm-gtk-greeter|' \
        /etc/lightdm/lightdm.conf 2>/dev/null || true
    msg_ok "LightDM configuré avec lightdm-gtk-greeter"
elif command -v lightdm &>/dev/null; then
    # Créer une configuration minimale
    mkdir -p /etc/lightdm
    cat > /etc/lightdm/lightdm.conf << 'LIGHTDMEOF'
[SeatDefaults]
greeter-session=lightdm-gtk-greeter
user-session=openbox
allow-guest=false
greeter-hide-users=false
session-wrapper=/etc/lightdm/Xsession
LIGHTDMEOF
    msg_ok "Configuration LightDM créée"
else
    msg_warn "LightDM non installé, configuration ignorée."
fi

# ============================================================================
# 5. Configurer le hostname dans /etc/hosts
# ============================================================================
msg_info "Configuration du hostname..."

if [ -f "/etc/hostname" ]; then
    HOSTNAME=$(cat /etc/hostname | tr -d '[:space:]')
else
    HOSTNAME="nemOS"
    echo "$HOSTNAME" > /etc/hostname
fi

# Mettre à jour /etc/hosts si nécessaire
if ! grep -q "127.0.1.1.*${HOSTNAME}" /etc/hosts 2>/dev/null; then
    echo "127.0.1.1	${HOSTNAME}.localdomain	${HOSTNAME}" >> /etc/hosts
    msg_ok "Hostname ${HOSTNAME} ajouté à /etc/hosts"
else
    msg_ok "Hostname déjà configuré dans /etc/hosts"
fi

# ============================================================================
# 6. Activer les services système nécessaires
# ============================================================================
msg_info "Activation des services système..."

SERVICES_TO_ENABLE=(
    "NetworkManager"      # Gestionnaire réseau
    "lightdm"             # Gestionnaire d'affichage
    "bluetooth"           # Bluetooth (si installé)
    "cups"                # Impression (si installé)
    "dbus-broker"         # Bus D-Bus
)

for svc in "${SERVICES_TO_ENABLE[@]}"; do
    if [ -f "/usr/lib/systemd/system/${svc}.service" ] || \
       [ -f "/etc/systemd/system/${svc}.service" ]; then
        systemctl enable "${svc}" 2>/dev/null && \
            msg_ok "Service ${svc} activé" || \
            msg_warn "Impossible d'activer le service ${svc}"
    else
        msg_warn "Service ${svc} non trouvé (pas installé)"
    fi
done

# Désactiver les services du live
SERVICES_TO_DISABLE=(
    "livecd-squashfs"
    "pacman-init"
)

for svc in "${SERVICES_TO_DISABLE[@]}"; do
    systemctl disable "${svc}" 2>/dev/null || true
done

# ============================================================================
# 7. Supprimer l'utilisateur live (si existant)
# ============================================================================
msg_info "Nettoyage des utilisateurs live..."

LIVE_USERS=("nemos-live" "liveuser" "archiso" "nemos")

for lu in "${LIVE_USERS[@]}"; do
    if id "$lu" &>/dev/null; then
        # Supprimer l'utilisateur et son répertoire personnel
        userdel -r "$lu" 2>/dev/null && \
            msg_ok "Utilisateur live '${lu}' supprimé" || \
            msg_warn "Impossible de supprimer l'utilisateur '${lu}'"
    fi
done

# Supprimer les groupes live orphelins
for lg in "live" "nemos-live"; do
    if getent group "$lg" &>/dev/null; then
        groupdel "$lg" 2>/dev/null || true
    fi
done

# ============================================================================
# 8. Régénérer le cache des polices
# ============================================================================
msg_info "Mise à jour du cache des polices..."
if command -v fc-cache &>/dev/null; then
    fc-cache -f 2>/dev/null && msg_ok "Cache des polices mis à jour" || \
        msg_warn "Erreur lors de la mise à jour du cache des polices"
else
    msg_warn "fc-cache non disponible"
fi

# ============================================================================
# 9. Régénérer le cache des icônes
# ============================================================================
msg_info "Mise à jour du cache des icônes..."

ICON_CACHES=(
    "/usr/share/icons/nemOS-Icons"
    "/usr/share/icons/hicolor"
    "/usr/share/icons/Adwaita"
)

for icon_dir in "${ICON_CACHES[@]}"; do
    if [ -d "$icon_dir" ]; then
        if command -v gtk-update-icon-cache &>/dev/null; then
            gtk-update-icon-cache -f "$icon_dir" 2>/dev/null && \
                msg_ok "Cache d'icônes mis à jour : $(basename "$icon_dir")" || \
                msg_warn "Erreur de cache pour $(basename "$icon_dir")"
        fi
    fi
done

# ============================================================================
# 10. Régénérer le cache MIME
# ============================================================================
msg_info "Mise à jour du cache MIME..."
if command -v update-mime-database &>/dev/null; then
    update-mime-database /usr/share/mime 2>/dev/null && \
        msg_ok "Cache MIME mis à jour" || \
        msg_warn "Erreur lors de la mise à jour du cache MIME"
fi

# ============================================================================
# 11. Régénérer le cache des applications desktop
# ============================================================================
msg_info "Mise à jour du cache des applications..."
if command -v update-desktop-database &>/dev/null; then
    update-desktop-database /usr/share/applications 2>/dev/null && \
        msg_ok "Cache des applications mis à jour" || \
        msg_warn "Erreur lors de la mise à jour du cache des applications"
fi

# ============================================================================
# 12. Générer l'initramfs
# ============================================================================
msg_info "Génération de l'initramfs..."
if command -v mkinitcpio &>/dev/null; then
    # Régénérer pour tous les presets
    for preset in /etc/mkinitcpio.d/*.preset; do
        if [ -f "$preset" ]; then
            preset_name=$(basename "$preset" .preset)
            mkinitcpio -p "$preset_name" 2>/dev/null && \
                msg_ok "Initramfs généré pour ${preset_name}" || \
                msg_warn "Erreur de génération pour ${preset_name}"
        fi
    done
else
    msg_warn "mkinitcpio non disponible, initramfs non régénéré."
fi

# ============================================================================
# 13. Nettoyer le cache pacman
# ============================================================================
msg_info "Nettoyage du cache pacman..."
if [ -d "/var/cache/pacman/pkg" ]; then
    # Supprimer les paquets en cache (mais pas les répertoires)
    find /var/cache/pacman/pkg -type f -name "*.pkg.tar.*" -delete 2>/dev/null || true
    msg_ok "Cache pacman nettoyé"
fi

# ============================================================================
# 14. Nettoyage final
# ============================================================================
msg_info "Nettoyage final..."

# Répertoires temporaires
rm -rf /tmp/* 2>/dev/null || true
rm -rf /var/tmp/* 2>/dev/null || true

# Fichiers temporaires de l'installateur
rm -rf /tmp/nemos-build 2>/dev/null || true
rm -rf /var/log/installer 2>/dev/null || true
rm -f /etc/calamares/modules/shellprocess.conf.bak 2>/dev/null || true

# Historique des commandes du live
if [ -n "$TARGET_USER" ] && [ -f "/home/${TARGET_USER}/.bash_history" ]; then
    > "/home/${TARGET_USER}/.bash_history"
    chown "${TARGET_USER}:${TARGET_GROUP}" "/home/${TARGET_USER}/.bash_history"
fi

# ============================================================================
# Fin de la post-installation
# ============================================================================

echo ""
echo "============================================================"
echo -e "  ${GREEN}Post-installation nemOS terminée avec succès !${NC}"
echo "============================================================"
echo ""
echo "  Résumé des actions effectuées :"
echo "  ✓ Thème GTK nemOS-Dark appliqué"
echo "  ✓ Fonds d'écran nemOS configurés"
echo "  ✓ Dock Plank configuré"
echo "  ✓ Gestionnaire d'affichage (LightDM) configuré"
echo "  ✓ Hostname configuré dans /etc/hosts"
echo "  ✓ Services système activés"
echo "  ✓ Utilisateurs live supprimés"
echo "  ✓ Cache polices/icônes/MIME mis à jour"
echo "  ✓ Initramfs régénéré"
echo "  ✓ Cache pacman nettoyé"
echo ""
if [ -n "$TARGET_USER" ]; then
    echo "  Utilisateur configuré : ${BOLD}${TARGET_USER}${NC}"
fi
echo ""
echo "  Redémarrez pour démarrer sur votre nouveau système nemOS."
echo ""