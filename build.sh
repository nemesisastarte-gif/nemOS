#!/usr/bin/env bash
# ============================================================================
# nemOS - Script de construction principal de l'ISO
# Basé sur le flux de travail mkarchiso d'Arch Linux
# ============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Variables globales
# ---------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKDIR="/tmp/nemos-build"
OUTDIR="/tmp/nemos-out"
PROFILE_DIR="${SCRIPT_DIR}/nem"
LOG_FILE="${WORKDIR}/build.log"
VERBOSE=false
CLEAN=false
TIMESTAMP="$(date +%Y%m%d%H%M)"

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # Pas de couleur

# ---------------------------------------------------------------------------
# Fonctions utilitaires
# ---------------------------------------------------------------------------

# Afficher un message d'information
msg_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Afficher un message de succès
msg_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Afficher un avertissement
msg_warn() {
    echo -e "${YELLOW}[ATTENTION]${NC} $1"
}

# Afficher une erreur
msg_err() {
    echo -e "${RED}[ERREUR]${NC} $1" >&2
}

# Afficher une étape de progression
msg_step() {
    echo -e "\n${BOLD}${CYAN}===> $1 <===${NC}\n"
}

# Afficher la taille d'un fichier de manière lisible
human_size() {
    local bytes
    bytes="$(stat -c %s "$1" 2>/dev/null || echo 0)"
    if command -v numfmt &>/dev/null; then
        numfmt --to=iec-i --suffix=B "${bytes}"
    else
        echo "${bytes} octets"
    fi
}

# ---------------------------------------------------------------------------
# Vérification des privilèges root
# ---------------------------------------------------------------------------
check_root() {
    if [[ "${EUID}" -ne 0 ]]; then
        msg_err "Ce script doit être exécuté en tant que root (sudo)."
        msg_err "Utilisez : sudo $0"
        exit 1
    fi
    msg_ok "Privilèges root vérifiés."
}

# ---------------------------------------------------------------------------
# Vérification des dépendances
# ---------------------------------------------------------------------------
check_dependencies() {
    msg_step "Vérification des dépendances requises"

    local deps=(
        "arch-install-scripts"
        "mtools"
        "squashfs-tools"
        "xorriso"
        "e2fsprogs"
        "git"
        "pv"
        "zstd"
    )

    local missing=()
    local cmd_map=(
        ["arch-install-scripts"]="arch-chroot"
        ["mtools"]="mmd"
        ["squashfs-tools"]="mksquashfs"
        ["xorriso"]="xorriso"
        ["e2fsprogs"]="mkfs.ext4"
        ["git"]="git"
        ["pv"]="pv"
        ["zstd"]="zstd"
    )

    for dep in "${deps[@]}"; do
        local cmd="${cmd_map[${dep}]}"
        if ! command -v "${cmd}" &>/dev/null; then
            missing+=("${dep}")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        msg_err "Dépendances manquantes : ${missing[*]}"
        msg_err "Installez-les avec : pacman -S ${missing[*]}"
        exit 1
    fi

    msg_ok "Toutes les dépendances sont installées."

    # Vérification supplémentaire : mkarchiso
    if ! command -v mkarchiso &>/dev/null; then
        msg_err "mkarchiso est introuvable. Installez archiso : pacman -S archiso"
        exit 1
    fi
    msg_ok "mkarchiso trouvé : $(command -v mkarchiso)"
}

# ---------------------------------------------------------------------------
# Nettoyage des artefacts de construction précédents
# ---------------------------------------------------------------------------
clean_build() {
    msg_step "Nettoyage des artefacts de construction précédents"

    local cleaned=false

    if [[ -d "${WORKDIR}" ]]; then
        msg_info "Suppression du répertoire de travail : ${WORKDIR}"
        rm -rf "${WORKDIR}"
        cleaned=true
    fi

    if [[ -d "${OUTDIR}" ]]; then
        msg_info "Suppression du répertoire de sortie : ${OUTDIR}"
        rm -rf "${OUTDIR}"
        cleaned=true
    fi

    if [[ "${cleaned}" == false ]]; then
        msg_info "Aucun artefact de construction précédent trouvé."
    else
        msg_ok "Nettoyage terminé."
    fi
}

# ---------------------------------------------------------------------------
# Création des répertoires de travail
# ---------------------------------------------------------------------------
create_workdirs() {
    msg_step "Création des répertoires de travail"

    mkdir -p "${WORKDIR}"
    mkdir -p "${OUTDIR}"

    msg_ok "Répertoire de travail créé : ${WORKDIR}"
    msg_ok "Répertoire de sortie créé   : ${OUTDIR}"
}

# ---------------------------------------------------------------------------
# Vérification du profil de construction
# ---------------------------------------------------------------------------
check_profile() {
    msg_step "Vérification du profil de construction"

    if [[ ! -d "${PROFILE_DIR}" ]]; then
        msg_err "Le répertoire du profil est introuvable : ${PROFILE_DIR}"
        msg_err "Assurez-vous que le répertoire 'nem/' existe à côté de build.sh"
        exit 1
    fi

    # Vérifier les fichiers essentiels du profil
    local required_files=(
        "profiledef.sh"
        "packages.x86_64"
    )

    for f in "${required_files[@]}"; do
        if [[ ! -f "${PROFILE_DIR}/${f}" ]]; then
            msg_warn "Fichier de profil manquant (optionnel pour le moment) : ${f}"
        fi
    done

    msg_ok "Profil de construction vérifié : ${PROFILE_DIR}"
}

# ---------------------------------------------------------------------------
# Construction de l'ISO avec mkarchiso
# ---------------------------------------------------------------------------
build_iso() {
    msg_step "Construction de l'ISO nemOS"
    msg_info "Début de la construction à $(date)"
    msg_info "Répertoire de travail : ${WORKDIR}"
    msg_info "Répertoire de sortie   : ${OUTDIR}"
    msg_info "Profil                 : ${PROFILE_DIR}"

    # Construction de la commande mkarchiso
    local mkarchiso_cmd=(
        mkarchiso
    )

    if [[ "${VERBOSE}" == true ]]; then
        mkarchiso_cmd+=("-v")
        msg_info "Mode verbeux activé."
    fi

    mkarchiso_cmd+=(
        -w "${WORKDIR}"
        -o "${OUTDIR}"
        "${PROFILE_DIR}"
    )

    msg_info "Exécution de : ${mkarchiso_cmd[*]}"
    echo ""

    # Exécution de la construction
    if "${mkarchiso_cmd[@]}" 2>&1 | tee "${LOG_FILE}"; then
        msg_ok "Construction mkarchiso terminée avec succès."
    else
        msg_err "La construction mkarchiso a échoué. Consultez le journal : ${LOG_FILE}"
        exit 1
    fi
}

# ---------------------------------------------------------------------------
# Compression supplémentaire de l'ISO avec zstd (si nécessaire)
# ---------------------------------------------------------------------------
compress_iso() {
    msg_step "Vérification et compression de l'ISO"

    local iso_file
    iso_file="$(find "${OUTDIR}" -maxdepth 1 -name '*.iso' -type f 2>/dev/null | head -n1)"

    if [[ -z "${iso_file}" ]]; then
        msg_err "Aucun fichier ISO trouvé dans ${OUTDIR}"
        exit 1
    fi

    local original_size
    original_size="$(human_size "${iso_file}")"
    msg_info "ISO trouvée : ${iso_file} (${original_size})"

    # Vérifier si l'ISO est déjà compressée de manière optimale
    # On vérifie la taille ; si elle dépasse 2 Gio, on peut proposer une recompression
    local iso_bytes
    iso_bytes="$(stat -c %s "${iso_file}")"
    local max_size=$((2 * 1024 * 1024 * 1024))  # 2 Gio

    if [[ "${iso_bytes}" -gt "${max_size}" ]]; then
        msg_warn "L'ISO dépasse 2 Gio (${original_size})."
        msg_info "L'ISO sera conservée telle quelle — mkarchiso gère déjà la compression."
        msg_info "Pour réduire la taille, envisagez de supprimer des paquets dans le profil."
    else
        msg_ok "Taille de l'ISO raisonnable (${original_size}), pas de recompression nécessaire."
    fi
}

# ---------------------------------------------------------------------------
# Génération de la somme de contrôle SHA256
# ---------------------------------------------------------------------------
generate_checksum() {
    msg_step "Génération de la somme de contrôle SHA256"

    local iso_file
    iso_file="$(find "${OUTDIR}" -maxdepth 1 -name '*.iso' -type f 2>/dev/null | head -n1)"

    if [[ -z "${iso_file}" ]]; then
        msg_err "Aucun fichier ISO trouvé pour la somme de contrôle."
        exit 1
    fi

    # Générer le fichier .sha256
    (cd "${OUTDIR}" && sha256sum "$(basename "${iso_file}")" > "$(basename "${iso_file}").sha256")

    msg_ok "Somme de contrôle générée : ${iso_file}.sha256"

    if [[ "${VERBOSE}" == true ]]; then
        echo ""
        msg_info "Contenu du fichier SHA256 :"
        cat "${iso_file}.sha256"
    fi
}

# ---------------------------------------------------------------------------
# Rapport final
# ---------------------------------------------------------------------------
final_report() {
    msg_step "Rapport final de la construction"

    local iso_file
    iso_file="$(find "${OUTDIR}" -maxdepth 1 -name '*.iso' -type f 2>/dev/null | head -n1)"

    if [[ -z "${iso_file}" ]]; then
        msg_err "Aucun fichier ISO trouvé dans le répertoire de sortie."
        exit 1
    fi

    local final_size
    final_size="$(human_size "${iso_file}")"
    local sha256_file="${iso_file}.sha256"

    echo ""
    echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}${BOLD}║         Construction nemOS terminée avec succès         ║${NC}"
    echo -e "${GREEN}${BOLD}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${BOLD}║                                                              ║${NC}"
    echo -e "${BOLD}║  ISO        : ${iso_file}"
    echo -e "${BOLD}║  Taille     : ${final_size}"
    if [[ -f "${sha256_file}" ]]; then
        echo -e "${BOLD}║  SHA256     : ${sha256_file}"
    fi
    echo -e "${BOLD}║  Journal    : ${LOG_FILE}"
    echo -e "${BOLD}║  Horodatage : ${TIMESTAMP}"
    echo -e "${BOLD}║                                                              ║${NC}"
    echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    msg_info "Pour tester l'ISO dans une machine virtuelle :"
    echo "  qemu-system-x86_64 -m 2048 -cdrom \"${iso_file}\" -boot d"
    echo ""
    msg_info "Pour flasher sur une clé USB :"
    echo "  sudo dd if=\"${iso_file}\" of=/dev/sdX bs=4M status=progress && sync"
    echo ""
}

# ---------------------------------------------------------------------------
# Affichage de l'aide
# ---------------------------------------------------------------------------
usage() {
    cat <<EOF
${BOLD}Usage :${NC}
    sudo $0 [OPTIONS]

${BOLD}Description :${NC}
    Script principal de construction de l'ISO nemOS.
    Basé sur le flux de travail mkarchiso d'Arch Linux.

${BOLD}Options :${NC}
    -c, --clean      Nettoyer les artefacts de construction précédents
    -v, --verbose    Mode verbeux (journalisation détaillée)
    -h, --help       Afficher ce message d'aide

${BOLD}Exemples :${NC}
    sudo $0                  # Construction normale
    sudo $0 -v               # Construction avec mode verbeux
    sudo $0 -c               # Nettoyer uniquement
    sudo $0 -c -v            # Nettoyer puis construire en mode verbeux

${BOLD}Variables d'environnement (facultatif) :${NC}
    WORKDIR    Répertoire de travail (défaut : /tmp/nemos-build)
    OUTDIR     Répertoire de sortie   (défaut : /tmp/nemos-out)

EOF
}

# ---------------------------------------------------------------------------
# Point d'entrée principal
# ---------------------------------------------------------------------------
main() {
    echo -e "${BOLD}${CYAN}"
    echo "  _  _   __   ___  _  _  ____  ____  _  _  ____  _  _  ____  ____"
    echo " / )( \ / _\ / __)/ )( \(___ \(  __)/ )( \(  _ \( \/ )(  _ \(  __)"
    echo " ) __ (/    ( (__ ) \/ ( / __/ ) _) ) \/ ( )   / )  (  )   / ) _)"
    echo " \_)(_/ \_/\_/\___)\____/(____)(__)  \____/(__\_)(_/\_)(____)(____)"
    echo -e "${NC}"
    echo -e "${BOLD}              Système de construction de l'ISO${NC}"
    echo -e "${BOLD}              Basé sur archiso / mkarchiso${NC}"
    echo ""

    # Analyse des arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -c|--clean)
                CLEAN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -h|--help)
                usage
                exit 0
                ;;
            *)
                msg_err "Option inconnue : $1"
                usage
                exit 1
                ;;
        esac
    done

    # Si seul le nettoyage est demandé
    if [[ "${CLEAN}" == true && "${VERBOSE}" == false ]]; then
        # Vérifier si mkarchiso existe avant de nettoyer
        # (pas de vérification complète des dépendances pour le nettoyage seul)
        clean_build
        msg_ok "Nettoyage terminé. Utilisez '$0' sans --clean pour lancer la construction."
        exit 0
    fi

    # Étapes de construction
    check_root
    check_dependencies

    if [[ "${CLEAN}" == true ]]; then
        clean_build
    fi

    create_workdirs
    check_profile
    build_iso
    compress_iso
    generate_checksum
    final_report

    msg_ok "Toutes les étapes de construction sont terminées !"
}

# Exécution du point d'entrée
main "$@"