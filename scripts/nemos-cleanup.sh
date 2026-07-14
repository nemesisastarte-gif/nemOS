#!/usr/bin/env bash
# ============================================================================
# nemOS - Script de nettoyage post-construction
# Exécuté à l'intérieur du chroot (airootfs) pour minimiser la taille de l'ISO
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Variables globales
# ---------------------------------------------------------------------------
SPACE_BEFORE=0
SPACE_AFTER=0

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

# ---------------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------------

msg_info()  { echo -e "${BLUE}[NETTOYAGE]${NC} $1"; }
msg_ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
msg_warn()  { echo -e "${YELLOW}[ATTENTION]${NC} $1"; }

# Obtenir l'espace libre du système de fichiers racine en Ko
get_free_space() {
    df -k / | awk 'NR==2 {print $4}'
}

# Afficher une taille en format lisible
human_size() {
    local kb="$1"
    if command -v numfmt &>/dev/null; then
        echo "$(numfmt --to=iec-i --suffix=B "$((kb * 1024))")"
    else
        echo "${kb} Ko"
    fi
}

# ---------------------------------------------------------------------------
# Étape 1 : Suppression du cache pacman
# ---------------------------------------------------------------------------
clean_pacman_cache() {
    msg_info "Suppression du cache pacman..."
    if [[ -d /var/cache/pacman/pkg ]]; then
        local before
        before="$(du -sk /var/cache/pacman/pkg 2>/dev/null | awk '{print $1}')"
        rm -rf /var/cache/pacman/pkg/*
        msg_ok "Cache pacman vidé (environ $(human_size "${before}") récupérés)."
    else
        msg_warn "Répertoire du cache pacman introuvable."
    fi
}

# ---------------------------------------------------------------------------
# Étape 2 : Suppression des fichiers journaux
# ---------------------------------------------------------------------------
clean_logs() {
    msg_info "Suppression des fichiers journaux..."

    # Journaux généraux
    if compgen -G /var/log/*.log &>/dev/null; then
        rm -f /var/log/*.log
        msg_ok "Journaux /var/log/*.log supprimés."
    fi

    # Journaux systemd/journal
    if [[ -d /var/log/journal ]]; then
        rm -rf /var/log/journal/*
        msg_ok "Journaux systemd /var/log/journal/ vidés."
    fi

    # Autres fichiers de journal courants
    for f in /var/log/pacman.log /var/log/lastlog /var/log/faillog /var/log/btmp; do
        if [[ -f "${f}" ]]; then
            > "${f}"  # Tronquer le fichier sans le supprimer (certains dépendent de lui)
        fi
    done
}

# ---------------------------------------------------------------------------
# Étape 3 : Suppression des fichiers temporaires
# ---------------------------------------------------------------------------
clean_temp() {
    msg_info "Suppression des fichiers temporaires..."

    # /tmp — attention : certains fichiers peuvent être montés, on utilise find
    if [[ -d /tmp ]]; then
        find /tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
        msg_ok "/tmp nettoyé."
    fi

    # /var/tmp
    if [[ -d /var/tmp ]]; then
        find /var/tmp -mindepth 1 -maxdepth 1 -exec rm -rf {} + 2>/dev/null || true
        msg_ok "/var/tmp nettoyé."
    fi
}

# ---------------------------------------------------------------------------
# Étape 4 : Suppression des pages de manuel non français/anglais
# ---------------------------------------------------------------------------
clean_man_pages() {
    msg_info "Suppression des pages de manuel dans les langues non désirées..."

    local man_dirs=()
    local keep_locales="fr fr_FR en en_US en_GB"

    # Trouver tous les répertoires de pages de manuel
    if [[ -d /usr/share/man ]]; then
        # Les locales à supprimer = toutes sauf fr* et en*
        while IFS= read -r -d '' locale_dir; do
            local locale_name
            locale_name="$(basename "${locale_dir}")"

            # Garder fr, fr_*, en, en_*
            local keep=false
            for kl in ${keep_locales}; do
                if [[ "${locale_name}" == "${kl}"* ]]; then
                    keep=true
                    break
                fi
            done

            # Supprimer les alias courants
            case "${locale_name}" in
                man|fr|fr_*|en|en_*) keep=true ;;
            esac

            if [[ "${keep}" == false ]]; then
                rm -rf "${locale_dir}"
            fi
        done < <(find /usr/share/man -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
    fi

    msg_ok "Pages de manuel nettoyées (conservées : ${keep_locales})."
}

# ---------------------------------------------------------------------------
# Étape 5 : Suppression des fichiers de locale non désirés
# ---------------------------------------------------------------------------
clean_locales() {
    msg_info "Suppression des fichiers de locale non désirés..."

    local keep_locales=("fr" "fr_FR" "en" "en_US" "en_GB" "C" "POSIX")

    # Nettoyer /usr/share/locale
    if [[ -d /usr/share/locale ]]; then
        while IFS= read -r -d '' locale_dir; do
            local locale_name
            locale_name="$(basename "${locale_dir}")"
            local keep=false

            for kl in "${keep_locales[@]}"; do
                if [[ "${locale_name}" == "${kl}" ]]; then
                    keep=true
                    break
                fi
            done

            # Garder aussi les locales qui commencent par fr ou en
            if [[ "${locale_name}" == fr_* || "${locale_name}" == en_* ]]; then
                keep=true
            fi

            if [[ "${keep}" == false ]]; then
                rm -rf "${locale_dir}"
            fi
        done < <(find /usr/share/locale -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
    fi

    # Nettoyer /usr/lib/locale (fichiers compilés glibc)
    if [[ -d /usr/lib/locale ]]; then
        while IFS= read -r -d '' locale_archive; do
            local locale_name
            locale_name="$(basename "${locale_archive}")"
            local keep=false

            for kl in "${keep_locales[@]}"; do
                if [[ "${locale_name}" == "${kl}" ]]; then
                    keep=true
                    break
                fi
            done

            if [[ "${locale_name}" == fr_* || "${locale_name}" == en_* ]]; then
                keep=true
            fi

            if [[ "${keep}" == false ]]; then
                rm -rf "${locale_archive}"
            fi
        done < <(find /usr/lib/locale -mindepth 1 -maxdepth 1 -type f -print0 2>/dev/null || true)
    fi

    msg_ok "Fichiers de locale nettoyés (conservés : ${keep_locales[*]})."
}

# ---------------------------------------------------------------------------
# Étape 6 : Suppression des modules du noyau inutilisés
# ---------------------------------------------------------------------------
clean_kernel_modules() {
    msg_info "Suppression des modules du noyau inutilisés..."

    local kernel_versions=()
    if [[ -d /usr/lib/modules ]]; then
        while IFS= read -r -d '' kv_dir; do
            kernel_versions+=("$(basename "${kv_dir}")")
        done < <(find /usr/lib/modules -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)
    fi

    if [[ ${#kernel_versions[@]} -eq 0 ]]; then
        msg_warn "Aucun module de noyau trouvé."
        return
    fi

    # Liste des motifs de modules à CONSERVER
    # Format : motif de chemin relatif au répertoire des modules
    local keep_patterns=(
        # Systèmes de fichiers essentiels
        "kernel/fs/ext4"
        "kernel/fs/squashfs"
        "kernel/fs/isofs"
        "kernel/fs/overlayfs"
        "kernel/fs/ramfs"
        "kernel/fs/tmpfs"
        "kernel/fs/proc"
        "kernel/fs/sysfs"
        "kernel/fs/devpts"
        "kernel/fs/cdrom"
        "kernel/fs/fat"
        "kernel/fs/vfat"
        "kernel/fs/ntfs"
        "kernel/fs/nls"
        # Stockage et disques
        "kernel/drivers/usb/storage"
        "kernel/drivers/ata"
        "kernel/drivers/scsi"
        "kernel/drivers/md"
        # Contrôleurs PCI/ACPI
        "kernel/drivers/acpi"
        "kernel/drivers/pci"
        # GPU et affichage
        "kernel/drivers/gpu/drm"
        # Bus et périphériques
        "kernel/drivers/i2c"
        "kernel/drivers/input/evdev"
        "kernel/drivers/input/uinput"
        "kernel/drivers/input/keyboard"
        "kernel/drivers/input/mouse"
        "kernel/drivers/input/touchscreen"
        "kernel/drivers/hid"
        "kernel/drivers/usb/core"
        "kernel/drivers/usb/host"
        # Audio
        "kernel/sound"
        # Réseau
        "kernel/net"
        "kernel/drivers/net/ethernet"
        "kernel/drivers/net/wireless"
        "kernel/drivers/net/usb"
        # Virtualisation
        "kernel/drivers/virtio"
        "kernel/drivers/vhost"
        "kernel/drivers/misc/vmw_balloon"
        # Bluetooth
        "kernel/net/bluetooth"
        "kernel/drivers/bluetooth"
        # Gestionnaire de périphériques
        "kernel/drivers/base"
        # Modules génériques et noyau
        "kernel/kernel"
        "kernel/lib"
        "kernel/arch"
        "kernel/crypto"
        "kernel/security"
        # Périphériques spécifiques
        "kernel/drivers/char"
        "kernel/drivers/thermal"
        "kernel/drivers/cpufreq"
        "kernel/drivers/cpuidle"
        "kernel/drivers/clk"
        "kernel/drivers/regulator"
        "kernel/drivers/reset"
        "kernel/drivers/firmware"
        # MMC/SD
        "kernel/drivers/mmc"
        # Série / UART
        "kernel/drivers/tty"
        "kernel/drivers/serial"
        # Watchdog
        "kernel/drivers/watchdog"
        # IOMMU
        "kernel/drivers/iommu"
    )

    for kv in "${kernel_versions[@]}"; do
        local mod_dir="/usr/lib/modules/${kv}"
        msg_info "Nettoyage des modules pour le noyau ${kv}..."

        # Construire une expression find pour les répertoires à supprimer
        # On supprime ce qui ne correspond à aucun motif de conservation
        while IFS= read -r -d '' mod_path; do
            local rel_path="${mod_path#${mod_dir}/}"
            local preserve=false

            for pattern in "${keep_patterns[@]}"; do
                if [[ "${rel_path}" == "${pattern}"* ]]; then
                    preserve=true
                    break
                fi
            done

            if [[ "${preserve}" == false ]]; then
                rm -rf "${mod_path}"
            fi
        done < <(find "${mod_dir}" -mindepth 1 -maxdepth 2 -type d -print0 2>/dev/null || true)

        # Reconstruire les dépendances des modules
        if [[ -x /usr/bin/depmod ]]; then
            depmod "${kv}" 2>/dev/null || msg_warn "depmod a échoué pour ${kv}."
        fi

        msg_ok "Modules du noyau ${kv} nettoyés."
    done
}

# ---------------------------------------------------------------------------
# Étape 7 : Suppression du firmware non désiré
# ---------------------------------------------------------------------------
clean_firmware() {
    msg_info "Suppression du firmware non désiré..."

    if [[ ! -d /usr/lib/firmware ]]; then
        msg_warn "Répertoire de firmware introuvable."
        return
    fi

    # Firmwares à CONSERVER (motifs de chemin)
    local keep_patterns=(
        "iwlwifi"
        "ath9k_htc"
        "ath10k"
        "radeon"
        "amdgpu"
        "i915"
        # Firmwares génériques / essentiels
        "keyspan"          # Clés USB série
        "cpia2"            # Caméras web
        "dvb-usb"          # Tuners TV USB
        "edgeport"         # Convertisseurs USB-série
        "emi26"
        "emi62"
        "fw_loader"        # Chargeur de firmware générique
        "htc_9271"         # ath9k HTC firmware
        "isl3887usb"       # Prism2.5/3 USB
        "kaweth"           # Pilote réseau USB
        "mt7601u"          # Médiatek WiFi
        "mt76"
        "r8169"            # Realtek Ethernet
        "rtl_nic"          # Realtek NIC
        "rtw88"            # Realtek WiFi
        "rtw89"            # Realtek WiFi
        "sxgbe"            # Samsung Ethernet
        "tg3"              # Broadcom Tigon3
    )

    while IFS= read -r -d '' fw_dir; do
        local fw_name
        fw_name="$(basename "${fw_dir}")"
        local keep=false

        for pattern in "${keep_patterns[@]}"; do
            if [[ "${fw_name}" == "${pattern}"* ]]; then
                keep=true
                break
            fi
        done

        if [[ "${keep}" == false ]]; then
            rm -rf "${fw_dir}"
        fi
    done < <(find /usr/lib/firmware -mindepth 1 -maxdepth 1 -type d -print0 2>/dev/null || true)

    # Supprimer aussi les fichiers firmware à la racine qui ne correspondent pas
    while IFS= read -r -d '' fw_file; do
        local fw_name
        fw_name="$(basename "${fw_file}")"
        local keep=false

        for pattern in "${keep_patterns[@]}"; do
            if [[ "${fw_name}" == "${pattern}"* ]]; then
                keep=true
                break
            fi
        done

        if [[ "${keep}" == false ]]; then
            rm -f "${fw_file}"
        fi
    done < <(find /usr/lib/firmware -maxdepth 1 -type f -print0 2>/dev/null || true)

    msg_ok "Firmware nettoyé (conservés : iwlwifi, ath9k_htc, ath10k, radeon, amdgpu, i915 et essentiels)."
}

# ---------------------------------------------------------------------------
# Étape 8 : Compression des pages de manuel avec gzip
# ---------------------------------------------------------------------------
compress_man_pages() {
    msg_info "Compression des pages de manuel avec gzip..."

    # Trouver les pages de manuel non compressées et les compresser
    local compressed=0

    while IFS= read -r -d '' manfile; do
        if ! file "${manfile}" | grep -q "compressed"; then
            gzip -9 -f "${manfile}" 2>/dev/null || true
            ((compressed++)) || true
        fi
    done < <(find /usr/share/man -type f -name '*.[1-9]' -print0 2>/dev/null || true)

    msg_ok "${compressed} pages de manuel compressées."
}

# ---------------------------------------------------------------------------
# Étape 9 : Suppression des symboles de débogage des binaires
# ---------------------------------------------------------------------------
strip_binaries() {
    msg_info "Suppression des symboles de débogage des binaires..."

    local stripped=0

    # Supprimer les symboles de débogage de tous les exécutables
    # --strip-all supprime tous les symboles (pas seulement le débogage)
    # --strip-unneeded est plus sûr pour les bibliothèques
    while IFS= read -r -d '' binary; do
        # Vérifier que c'est bien un binaire ELF
        if file "${binary}" 2>/dev/null | grep -q "ELF"; then
            strip --strip-all "${binary}" 2>/dev/null || \
            strip --strip-unneeded "${binary}" 2>/dev/null || true
            ((stripped++)) || true
        fi
    done < <(find /usr -type f -executable -print0 2>/dev/null || true)

    msg_ok "${stripped} binaires traités (symboles supprimés)."
}

# ---------------------------------------------------------------------------
# Étape 10 : Mise à zéro de l'espace libre pour une meilleure compression
# ---------------------------------------------------------------------------
zero_free_space() {
    msg_info "Mise à zéro de l'espace libre pour une meilleure compression..."
    msg_info "Cette opération peut prendre un certain moment..."

    # Créer un fichier rempli de zéros jusqu'à ce que le disque soit plein
    # puis le supprimer. Cela permet à squashfs/zstd de mieux compresser.
    dd if=/dev/zero of=/tmp/zero bs=1M status=progress 2>/dev/null || true
    rm -f /tmp/zero

    # Faire de même dans /var
    dd if=/dev/zero of=/var/tmp/zero bs=1M status=progress 2>/dev/null || true
    rm -f /var/tmp/zero

    # Synchroniser pour s'assurer que tout est écrit
    sync

    msg_ok "Espace libre mis à zéro."
}

# ---------------------------------------------------------------------------
# Rapport sur l'espace économisé
# ---------------------------------------------------------------------------
report_space_saved() {
    SPACE_AFTER="$(get_free_space)"
    local saved_kb=$((SPACE_AFTER - SPACE_BEFORE))

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║           Rapport de nettoyage nemOS                    ║${NC}"
    echo -e "${GREEN}${BOLD}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║                                                              ║${NC}"
    echo -e "${BOLD}║  Espace libre avant : $(human_size "${SPACE_BEFORE}")"
    echo -e "${BOLD}║  Espace libre après  : $(human_size "${SPACE_AFTER}")"
    echo -e "${BOLD}║  Espace récupéré     : $(human_size "${saved_kb}")"
    echo -e "${BOLD}║                                                              ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# ---------------------------------------------------------------------------
# Point d'entrée principal
# ---------------------------------------------------------------------------
main() {
    echo -e "${BOLD}${BLUE}"
    echo "  nemOS - Nettoyage post-construction"
    echo -e "${NC}"

    # Mesure de l'espace avant nettoyage
    SPACE_BEFORE="$(get_free_space)"
    msg_info "Espace libre avant nettoyage : $(human_size "${SPACE_BEFORE}")"
    echo ""

    # Exécution séquentielle de chaque étape de nettoyage
    clean_pacman_cache
    clean_logs
    clean_temp
    clean_man_pages
    clean_locales
    clean_kernel_modules
    clean_firmware
    compress_man_pages
    strip_binaries
    zero_free_space

    # Rapport final
    report_space_saved

    msg_ok "Nettoyage post-construction terminé avec succès !"
}

main "$@"