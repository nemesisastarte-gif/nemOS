#!/usr/bin/env bash
# ============================================================================
# nemOS - Gestionnaire de services système
#
# Outil d'aide pour gérer les services spécifiques à nemOS.
# Permet de lister, démarrer, arrêter, activer et désactiver les services
# système, ainsi que d'obtenir des recommandations matérielles.
#
# Utilisation :
#   sudo nemos-services [COMMANDE] [SERVICE]
#   sudo nemos-services list
#   sudo nemos-services start NetworkManager
#   sudo nemos-services recommend wifi
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Variables globales
# ---------------------------------------------------------------------------
NEMOS_VERSION="1.0"
SCRIPT_NAME="$(basename "$0")"

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

msg_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
msg_ok()      { echo -e "${GREEN}[  OK]${NC} $1"; }
msg_warn()    { echo -e "${YELLOW}[!  ]${NC} $1"; }
msg_err()     { echo -e "${RED}[ERR]${NC} $1" >&2; }
msg_section() { echo -e "\n${BOLD}${CYAN}── $1 ──${NC}\n"; }

# Indicateur d'état coloré
status_icon() {
    if [[ "$1" == "active" || "$1" == "enabled" ]]; then
        echo -e "${GREEN}●${NC}"
    elif [[ "$1" == "inactive" || "$1" == "disabled" ]]; then
        echo -e "${RED}○${NC}"
    elif [[ "$1" == "failed" ]]; then
        echo -e "${RED}✗${NC}"
    else
        echo -e "${YELLOW}?${NC}"
    fi
}

# ============================================================================
# Définition des services nemOS
#
# Chaque entrée contient :
#   - Le nom du service systemd
#   - Une description en français
#   - La catégorie (essentiel, réseau, matériel, optional)
#   - Si le service doit être actif par défaut
# ============================================================================

# Tableau associatif : nom_service -> "description|catégorie|par_défaut_actif"
declare -A NEMOS_SERVICES

# --- Services essentiels (toujours nécessaires) ---
NEMOS_SERVICES["NetworkManager"]="Gestionnaire de réseau|essentiel|oui"
NEMOS_SERVICES["dbus-broker"]="Bus de messages D-Bus|essentiel|oui"
NEMOS_SERVICES["systemd-timesyncd"]="Synchronisation de l'heure (NTP)|essentiel|oui"
NEMOS_SERVICES["haveged"]="Générateur d'entropie matérielle|essentiel|oui"
NEMOS_SERVICES["cronie"]="Planificateur de tâches périodiques|essentiel|oui"
NEMOS_SERVICES["journald"]="Journalisation système (systemd)|essentiel|oui"
NEMOS_SERVICES["logind"]="Gestion des sessions (systemd-logind)|essentiel|oui"
NEMOS_SERVICES["udevd"]="Gestion des périphériques (systemd-udevd)|essentiel|oui"

# --- Services réseau ---
NEMOS_SERVICES["bluetooth"]="Support Bluetooth|réseau|oui"
NEMOS_SERVICES["cups"]="Système d'impression CUPS|réseau|oui"
NEMOS_SERVICES["avahi-daemon"]="Découverte de services réseau (mDNS)|réseau|non"
NEMOS_SERVICES["sshd"]="Serveur SSH (accès distant)|réseau|non"
NEMOS_SERVICES["firewalld"]="Pare-feu dynamique|réseau|oui"
NEMOS_SERVICES["nftables"]="Pare-feu basé sur netfilter|réseau|non"
NEMOS_SERVICES["ModemManager"]="Gestionnaire de modems (3G/4G)|réseau|non"
NEMOS_SERVICES["wwan"]="Réseau mobile (broadband)|réseau|non"
NEMOS_SERVICES["openvpn-client@nemos"]="Client VPN OpenVPN (si configuré)|réseau|non"
NEMOS_SERVICES["tailscaled"]="VPN mesh Tailscale|réseau|non"
NEMOS_SERVICES["systemd-resolved"]="Résolution DNS (systemd)|réseau|non"

# --- Services matériel ---
NEMOS_SERVICES["lightdm"]="Gestionnaire de connexion graphique|matériel|oui"
NEMOS_SERVICES["fstrim.timer"]="Optimisation TRIM hebdomadaire (SSD)|matériel|oui"
NEMOS_SERVICES["acpid"]="Gestion des événements ACPI|matériel|oui"
NEMOS_SERVICES["tlp"]="Gestion d'énergie avancée (portables)|matériel|non"
NEMOS_SERVICES["upower"]="Gestion de l'alimentation|matériel|oui"
NEMOS_SERVICES["power-profiles-daemon"]="Profils d'alimentation|matériel|oui"
NEMOS_SERVICES["smartd"]="Surveillance S.M.A.R.T. des disques|matériel|non"
NEMOS_SERVICES["udisks2"]="Gestion des disques (UDisks2)|matériel|oui"
NEMOS_SERVICES["systemd-backlight"]="Sauvegarde de la luminosité|matériel|oui"
NEMOS_SERVICES["systemd-rfkill"]="Gestion radio (Wi-Fi/Bluetooth)|matériel|oui"

# --- Services facultatifs ---
NEMOS_SERVICES["pamac-daemon"]="Démon de gestion de paquets graphique|facultatif|non"
NEMOS_SERVICES["flatpak-system-helper"]="Assistance système Flatpak|facultatif|non"
NEMOS_SERVICES["org.cups.cupsd"]="Démon d'impression (alias)|facultatif|non"
NEMOS_SERVICES["docker"]="Moteur de conteneurs Docker|facultatif|non"
NEMOS_SERVICES["libvirtd"]="Hyperviseur KVM/QEMU (libvirt)|facultatif|non"
NEMOS_SERVICES["virtlogd"]="Journalisation libvirt|facultatif|non"
NEMOS_SERVICES["snapd"]="Gestionnaire de paquets Snap|facultatif|non"
NEMOS_SERVICES["apparmor"]="Contrôle d'accès obligatoire (AppArmor)|facultatif|non"
NEMOS_SERVICES["auditd"]="Audit de sécurité|facultatif|non"
NEMOS_SERVICES["fail2ban"]="Protection contre les attaques brute-force|facultatif|non"

# ============================================================================
# Commande : list — Lister tous les services nemOS
# ============================================================================
cmd_list() {
    msg_section "Services système nemOS"

    # Organiser par catégorie
    local categories=("essentiel" "réseau" "matériel" "facultatif")
    local cat_labels=(
        "Essentiels"
        "Réseau"
        "Matériel"
        "Facultatifs"
    )
    local cat_colors=(
        "${GREEN}"
        "${BLUE}"
        "${YELLOW}"
        "${DIM}"
    )

    for i in "${!categories[@]}"; do
        local cat="${categories[$i]}"
        local label="${cat_labels[$i]}"
        local color="${cat_colors[$i]}"

        echo -e "  ${BOLD}${color}┌─ ${label} ─────────────────────────────────────────┐${NC}"

        local first=true
        for svc in "${!NEMOS_SERVICES[@]}"; do
            local entry="${NEMOS_SERVICES[$svc]}"
            local svc_cat="${entry%%|*}"
            # Extraire la catégorie (deuxième champ)
            svc_cat="$(echo "${entry}" | cut -d'|' -f2)"

            if [[ "${svc_cat}" != "${cat}" ]]; then
                continue
            fi

            # Extraire la description
            local desc
            desc="$(echo "${entry}" | cut -d'|' -f1)"

            # Récupérer l'état actuel
            local state="inconnu"
            local enabled="inconnu"
            if systemctl list-unit-files "${svc}" &>/dev/null; then
                if systemctl is-active --quiet "${svc}" 2>/dev/null; then
                    state="active"
                elif systemctl is-failed --quiet "${svc}" 2>/dev/null; then
                    state="failed"
                else
                    state="inactive"
                fi

                if systemctl is-enabled --quiet "${svc}" 2>/dev/null; then
                    enabled="enabled"
                else
                    enabled="disabled"
                fi
            else
                state="non installé"
                enabled="—"
            fi

            # Afficher la ligne
            printf "  ${color}│${NC} %-35s %-30s %s %s\n" \
                "${svc}" \
                "${desc}" \
                "$(status_icon "${state}") ${state}" \
                "$(status_icon "${enabled}") ${enabled}"
        done

        echo -e "  ${BOLD}${color}└────────────────────────────────────────────────────┘${NC}"
        echo ""
    done

    echo -e "  ${DIM}Légende : ● = actif/enabled  ○ = inactif/disabled  ✗ = échoué  ? = inconnu${NC}"
    echo ""
}

# ============================================================================
# Commande : status — Afficher le statut détaillé d'un service
# ============================================================================
cmd_status() {
    local svc="$1"
    msg_section "Statut du service : ${svc}"

    if ! systemctl list-unit-files "${svc}" &>/dev/null; then
        msg_err "Le service '${svc}' n'existe pas sur ce système."
        return 1
    fi

    # Vérifier si c'est un service connu nemOS
    if [[ -n "${NEMOS_SERVICES[${svc}]+x}" ]]; then
        local entry="${NEMOS_SERVICES[${svc}]}"
        local desc
        desc="$(echo "${entry}" | cut -d'|' -f1)"
        local cat
        cat="$(echo "${entry}" | cut -d'|' -f2)"
        echo -e "  ${BOLD}Description :${NC}  ${desc}"
        echo -e "  ${BOLD}Catégorie   :${NC}  ${cat}"
        echo ""
    fi

    # Afficher le statut complet
    systemctl status --no-pager "${svc}" 2>/dev/null || true
    echo ""

    # Informations supplémentaires
    echo -e "  ${BOLD}Détails :${NC}"
    echo -e "    Activé au démarrage : $(systemctl is-enabled "${svc}" 2>/dev/null || echo 'inconnu')"
    echo -e "    État actuel        : $(systemctl is-active "${svc}" 2>/dev/null || echo 'inconnu')"
    echo -e "    PID du processus   : $(systemctl show --property MainPID --value "${svc}" 2>/dev/null || echo 'N/A')"
    echo -e "    Mémoire utilisée   : $(systemctl show --property MemoryCurrent --value "${svc}" 2>/dev/null || echo 'N/A')"
}

# ============================================================================
# Commande : start — Démarrer un service
# ============================================================================
cmd_start() {
    local svc="$1"
    msg_info "Démarrage du service '${svc}'..."

    if systemctl start "${svc}" 2>/dev/null; then
        msg_ok "Service '${svc}' démarré avec succès."
    else
        msg_err "Impossible de démarrer le service '${svc}'."
        msg_err "Consultez le journal : journalctl -u ${svc} -n 20"
        return 1
    fi
}

# ============================================================================
# Commande : stop — Arrêter un service
# ============================================================================
cmd_stop() {
    local svc="$1"
    msg_info "Arrêt du service '${svc}'..."

    if systemctl stop "${svc}" 2>/dev/null; then
        msg_ok "Service '${svc}' arrêté avec succès."
    else
        msg_err "Impossible d'arrêter le service '${svc}'."
        return 1
    fi
}

# ============================================================================
# Commande : restart — Redémarrer un service
# ============================================================================
cmd_restart() {
    local svc="$1"
    msg_info "Redémarrage du service '${svc}'..."

    if systemctl restart "${svc}" 2>/dev/null; then
        msg_ok "Service '${svc}' redémarré avec succès."
    else
        msg_err "Impossible de redémarrer le service '${svc}'."
        return 1
    fi
}

# ============================================================================
# Commande : enable — Activer un service au démarrage
# ============================================================================
cmd_enable() {
    local svc="$1"
    msg_info "Activation du service '${svc}' au démarrage..."

    if systemctl enable "${svc}" 2>/dev/null; then
        msg_ok "Service '${svc}' activé au démarrage."
    else
        msg_err "Impossible d'activer le service '${svc}'."
        return 1
    fi
}

# ============================================================================
# Commande : disable — Désactiver un service au démarrage
# ============================================================================
cmd_disable() {
    local svc="$1"
    msg_info "Désactivation du service '${svc}' au démarrage..."

    if systemctl disable "${svc}" 2>/dev/null; then
        msg_ok "Service '${svc}' désactivé au démarrage."
    else
        msg_err "Impossible de désactiver le service '${svc}'."
        return 1
    fi
}

# ============================================================================
# Commande : recommend — Recommandations matérielles
#
# Détecte le matériel et recommande les services à activer.
# ============================================================================
cmd_recommend() {
    local hardware="${1:-all}"

    msg_section "Recommandations de services pour le matériel détecté"

    case "${hardware}" in
        wifi|wi-fi|wireless)
            echo -e "  ${BOLD}Matériel : Wi-Fi${NC}"
            echo ""
            # Détecter les interfaces Wi-Fi
            local wifi_ifaces
            wifi_ifaces="$(iw dev 2>/dev/null | grep Interface | awk '{print $2}')"

            if [[ -n "${wifi_ifaces}" ]]; then
                echo -e "  ${GREEN}Interfaces Wi-Fi détectées :${NC}"
                for iface in ${wifi_ifaces}; do
                    echo -e "    • ${iface}"
                done
                echo ""
                echo -e "  ${BOLD}Services recommandés :${NC}"
                echo -e "    ${CYAN}• NetworkManager${NC}  — Déjà activé par défaut"
                echo -e "    ${CYAN}• wpa_supplicant${NC} — Gestion du Wi-Fi WPA/WPA2"
                echo ""
                echo -e "  ${BOLD}Actions suggérées :${NC}"
                echo -e "    sudo nemos-services enable wpa_supplicant"
                echo -e "    nmtui                              (pour configurer le Wi-Fi)"
            else
                msg_warn "Aucune interface Wi-Fi détectée sur ce système."
            fi
            ;;

        bluetooth|bt)
            echo -e "  ${BOLD}Matériel : Bluetooth${NC}"
            echo ""
            if hciconfig 2>/dev/null | grep -q "hci"; then
                echo -e "  ${GREEN}Contrôleur Bluetooth détecté.${NC}"
                echo ""
                echo -e "  ${BOLD}Services recommandés :${NC}"
                echo -e "    ${CYAN}• bluetooth${NC}       — Démon Bluetooth"
                echo -e "    ${CYAN}• obexd${NC}          — Partage de fichiers Bluetooth"
                echo ""
                echo -e "  ${BOLD}Actions suggérées :${NC}"
                echo -e "    sudo nemos-services enable bluetooth"
                echo -e "    sudo nemos-services start bluetooth"
                echo -e "    bluetoothctl                       (pour jumeler des appareils)"
            else
                msg_warn "Aucun contrôleur Bluetooth détecté."
                echo -e "  Le service bluetooth peut rester désactivé."
            fi
            ;;

        printer|imprimante|cups)
            echo -e "  ${BOLD}Matériel : Imprimante${NC}"
            echo ""
            echo -e "  ${BOLD}Services recommandés :${NC}"
            echo -e "    ${CYAN}• cups${NC}           — Système d'impression"
            echo -e "    ${CYAN}• avahi-daemon${NC}  — Découverte automatique d'imprimantes réseau"
            echo -e "    ${CYAN}• sane*${NC}         — Scanners (si applicable)"
            echo ""
            echo -e "  ${BOLD}Actions suggérées :${NC}"
            echo -e "    sudo nemos-services enable cups"
            echo -e "    sudo nemos-services start cups"
            echo -e "    sudo nemos-services enable avahi-daemon"
            echo -e "    http://localhost:631               (interface CUPS)"
            ;;

        laptop|portable|batterie)
            echo -e "  ${BOLD}Matériel : Ordinateur portable${NC}"
            echo ""
            # Détecter la batterie
            if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
                echo -e "  ${GREEN}Batterie détectée.${NC}"
            else
                msg_warn "Aucune batterie détectée. Ce système semble être un ordinateur de bureau."
            fi
            echo ""
            echo -e "  ${BOLD}Services recommandés :${NC}"
            echo -e "    ${CYAN}• tlp${NC}                      — Gestion d'énergie avancée"
            echo -e "    ${CYAN}• upower${NC}                   — Suivi de la batterie"
            echo -e "    ${CYAN}• power-profiles-daemon${NC}    — Profils d'alimentation"
            echo -e "    ${CYAN}• acpid${NC}                   — Événements ACPI (boutons)"
            echo -e "    ${CYAN}• systemd-backlight${NC}        — Sauvegarde luminosité"
            echo -e "    ${CYAN}• logind-handle-lid-switch${NC} — Gestion du capot"
            echo ""
            echo -e "  ${BOLD}Actions suggérées :${NC}"
            echo -e "    sudo nemos-services enable tlp"
            echo -e "    sudo nemos-services enable upower"
            echo -e "    sudo nemos-services enable acpid"
            echo -e "    sudo nemos-services enable power-profiles-daemon"
            echo -e "    tlp-stat -s                         (statut de la batterie)"
            ;;

        ssd|trim|solid-state)
            echo -e "  ${BOLD}Matériel : Disque SSD${NC}"
            echo ""
            # Détecter les disques rotatifs vs SSD
            local has_ssd=false
            for block in /sys/block/*; do
                local rotational
                rotational="$(cat "${block}/queue/rotational" 2>/dev/null || echo 1)"
                if [[ "${rotational}" == "0" ]]; then
                    has_ssd=true
                    echo -e "  ${GREEN}SSD détecté : $(basename "${block}")${NC}"
                fi
            done

            if [[ "${has_ssd}" == true ]]; then
                echo ""
                echo -e "  ${BOLD}Services recommandés :${NC}"
                echo -e "    ${CYAN}• fstrim.timer${NC}  — TRIM hebdomadaire automatique"
                echo -e "    ${CYAN}• udisks2${NC}       — Gestion des disques"
                echo ""
                echo -e "  ${BOLD}Actions suggérées :${NC}"
                echo -e "    sudo nemos-services enable fstrim.timer"
                echo -e "    sudo fstrim -v /              (TRIM manuel immédiat)"
                echo -e "    lsblk -o NAME,ROTA,DISK-SEQ  (vérifier le type de disque)"
            else
                msg_warn "Aucun SSD détecté. Les services TRIM ne sont pas nécessaires."
            fi
            ;;

        gpu|graphique|video|nvidia|amdgpu|intel)
            echo -e "  ${BOLD}Matériel : Carte graphique${NC}"
            echo ""
            # Détecter les pilotes GPU
            if lspci 2>/dev/null | grep -qi "nvidia"; then
                echo -e "  ${GREEN}GPU NVIDIA détectée.${NC}"
                echo -e "  ${BOLD}Services recommandés :${NC}"
                echo -e "    ${CYAN}• nvidia-persistenced${NC}  — Maintien de l'état GPU"
                echo -e "    ${CYAN}• nvidia-suspend${NC}       — Suspend/Resume GPU"
                echo -e "    ${CYAN}• nvidia-hibernate${NC}     — Hibernation GPU"
                echo -e "    ${CYAN}• nvidia-resume${NC}        — Reprise après hibernation"
                echo ""
                echo -e "  ${BOLD}Actions suggérées :${NC}"
                echo -e "    sudo nemos-services enable nvidia-persistenced"
                echo -e "    nvidia-smi                      (monitoring GPU)"
            elif lspci 2>/dev/null | grep -qi "amdgpu\|radeon\|advanced micro devices"; then
                echo -e "  ${GREEN}GPU AMD détectée.${NC}"
                echo -e "  ${BOLD}Services recommandés :${NC}"
                echo -e "    ${CYAN}• power-profiles-daemon${NC}  — Profils d'alimentation GPU"
                echo ""
                echo -e "  ${BOLD}Actions suggérées :${NC}"
                echo -e "    sudo nemos-services enable power-profiles-daemon"
            elif lspci 2>/dev/null | grep -qi "intel.*vga\|integrated graphics"; then
                echo -e "  ${GREEN}GPU Intel détectée.${NC}"
                echo -e "  ${BOLD}Services recommandés :${NC}"
                echo -e "    ${CYAN}• power-profiles-daemon${NC}  — Profils d'alimentation GPU"
                echo ""
                echo -e "  ${BOLD}Actions suggérées :${NC}"
                echo -e "    sudo nemos-services enable power-profiles-daemon"
            else
                msg_warn "Impossible de détecter le type de GPU."
                echo -e "  Affichage les informations PCI disponibles :"
                lspci 2>/dev/null | grep -i "vga\|3d\|display" || echo "    (aucune information disponible)"
            fi
            ;;

        vm|virtuel|virtualbox|vmware|qemu)
            echo -e "  ${BOLD}Matériel : Machine virtuelle${NC}"
            echo ""
            if systemd-detect-virt 2>/dev/null | grep -q "oracle\|vmware\|kvm\|qemu"; then
                local vm_type
                vm_type="$(systemd-detect-virt 2>/dev/null)"
                echo -e "  ${GREEN}Machine virtuelle détectée : ${vm_type}${NC}"
                echo ""
                echo -e "  ${BOLD}Services recommandés :${NC}"
                echo -e "    ${CYAN}• spice-vdagentd${NC}  — Intégration SPICE (si applicable)"
                echo -e "    ${CYAN}• qemu-guest-agent${NC} — Agent invité QEMU/KVM"
                echo -e "    ${CYAN}• vmtoolsd${NC}        — VMware Tools (si VMware)"
                echo ""
                echo -e "  ${BOLD}Actions suggérées :${NC}"
                case "${vm_type}" in
                    oracle)
                        echo -e "    sudo nemos-services enable vboxservice"
                        ;;
                    vmware)
                        echo -e "    sudo pacman -S open-vm-tools"
                        echo -e "    sudo nemos-services enable vmtoolsd"
                        ;;
                    kvm|qemu)
                        echo -e "    sudo pacman -S qemu-guest-agent"
                        echo -e "    sudo nemos-services enable qemu-guest-agent"
                        ;;
                esac
            else
                msg_warn "Aucune virtualisation détectée. Ce système semble être physique."
            fi
            ;;

        all)
            # Lancer toutes les détections
            echo -e "  ${BOLD}Analyse complète du système...${NC}"
            echo ""

            # Résumé matériel
            echo -e "  ${BOLD}Matériel détecté :${NC}"
            echo -e "    Processeur  : $(lscpu 2>/dev/null | grep "Model name" | head -1 | cut -d: -f2 | xargs || echo 'inconnu')"
            echo -e "    Mémoire RAM : $(free -h 2>/dev/null | awk '/Mem:/ {print $2}' || echo 'inconnue')"
            echo -e "    Virtualisation : $(systemd-detect-virt 2>/dev/null || echo 'physique')"
            echo ""

            # Recommandations par catégorie
            for hw in wifi bluetooth printer laptop ssd gpu vm; do
                "$0" recommend "${hw}" 2>/dev/null || true
            done

            echo ""
            msg_section "Résumé des recommandations"
            echo -e "  Exécutez les commandes suggérées ci-dessus pour optimiser votre système."
            echo -e "  Utilisez ${BOLD}sudo nemos-services list${NC} pour voir l'état de tous les services."
            ;;

        *)
            msg_err "Catégorie de matériel inconnue : '${hardware}'"
            echo ""
            echo -e "  ${BOLD}Catégories disponibles :${NC}"
            echo -e "    wifi        Wi-Fi et réseau sans fil"
            echo -e "    bluetooth   Bluetooth"
            echo -e "    printer    Imprimantes et scanners"
            echo -e "    laptop     Ordinateurs portables (batterie, gestion d'énergie)"
            echo -e "    ssd         Disques SSD (TRIM)"
            echo -e "    gpu         Cartes graphiques (NVIDIA, AMD, Intel)"
            echo -e "    vm          Machines virtuelles"
            echo -e "    all         Analyse complète (toutes les catégories)"
            return 1
            ;;
    esac
    echo ""
}

# ============================================================================
# Affichage de l'aide
# ============================================================================
usage() {
    echo -e "${BOLD}nemOS — Gestionnaire de services système${NC} (v${NEMOS_VERSION})"
    echo ""
    echo -e "${BOLD}Utilisation :${NC}"
    echo -e "  sudo ${SCRIPT_NAME} <commande> [service|catégorie]"
    echo ""
    echo -e "${BOLD}Commandes :${NC}"
    echo -e "  ${CYAN}list${NC}                       Lister tous les services nemOS et leur état"
    echo -e "  ${CYAN}status <service>${NC}            Afficher le statut détaillé d'un service"
    echo -e "  ${CYAN}start <service>${NC}             Démarrer un service"
    echo -e "  ${CYAN}stop <service>${NC}              Arrêter un service"
    echo -e "  ${CYAN}restart <service>${NC}           Redémarrer un service"
    echo -e "  ${CYAN}enable <service>${NC}            Activer un service au démarrage"
    echo -e "  ${CYAN}disable <service>${NC}           Désactiver un service au démarrage"
    echo -e "  ${CYAN}recommend [catégorie]${NC}       Recommandations matérielles"
    echo ""
    echo -e "${BOLD}Catégories pour recommend :${NC}"
    echo -e "  wifi, bluetooth, printer, laptop, ssd, gpu, vm, all"
    echo ""
    echo -e "${BOLD}Exemples :${NC}"
    echo -e "  sudo ${SCRIPT_NAME} list"
    echo -e "  sudo ${SCRIPT_NAME} status NetworkManager"
    echo -e "  sudo ${SCRIPT_NAME} start bluetooth"
    echo -e "  sudo ${SCRIPT_NAME} enable docker"
    echo -e "  sudo ${SCRIPT_NAME} recommend wifi"
    echo -e "  sudo ${SCRIPT_NAME} recommend all"
    echo ""
}

# ============================================================================
# Vérification des privilèges
# ============================================================================
check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        # Seules les commandes "list", "recommend" et l'aide sont autorisées sans root
        case "${1:-}" in
            list|recommend|--help|-h|help|"")
                # Autorisé sans root
                return 0
                ;;
            *)
                msg_err "Cette commande nécessite les privilèges root."
                msg_err "Utilisez : sudo ${SCRIPT_NAME} $*"
                exit 1
                ;;
        esac
    fi
}

# ============================================================================
# Point d'entrée principal
# ============================================================================
main() {
    # Si aucun argument, afficher l'aide
    if [[ $# -eq 0 ]]; then
        usage
        exit 0
    fi

    local command="$1"
    shift

    # Vérification des privilèges pour les commandes de modification
    check_root "${command}" "$@"

    case "${command}" in
        list)
            cmd_list
            ;;
        status)
            if [[ $# -eq 0 ]]; then
                msg_err "Veuillez spécifier un service. Exemple : ${SCRIPT_NAME} status NetworkManager"
                exit 1
            fi
            cmd_status "$1"
            ;;
        start)
            if [[ $# -eq 0 ]]; then
                msg_err "Veuillez spécifier un service. Exemple : ${SCRIPT_NAME} start bluetooth"
                exit 1
            fi
            cmd_start "$1"
            ;;
        stop)
            if [[ $# -eq 0 ]]; then
                msg_err "Veuillez spécifier un service. Exemple : ${SCRIPT_NAME} stop bluetooth"
                exit 1
            fi
            cmd_stop "$1"
            ;;
        restart)
            if [[ $# -eq 0 ]]; then
                msg_err "Veuillez spécifier un service. Exemple : ${SCRIPT_NAME} restart NetworkManager"
                exit 1
            fi
            cmd_restart "$1"
            ;;
        enable)
            if [[ $# -eq 0 ]]; then
                msg_err "Veuillez spécifier un service. Exemple : ${SCRIPT_NAME} enable tlp"
                exit 1
            fi
            cmd_enable "$1"
            ;;
        disable)
            if [[ $# -eq 0 ]]; then
                msg_err "Veuillez spécifier un service. Exemple : ${SCRIPT_NAME} disable docker"
                exit 1
            fi
            cmd_disable "$1"
            ;;
        recommend|rec|recommandations)
            cmd_recommend "${1:-all}"
            ;;
        -h|--help|help)
            usage
            ;;
        *)
            msg_err "Commande inconnue : '${command}'"
            echo ""
            usage
            exit 1
            ;;
    esac
}

main "$@"