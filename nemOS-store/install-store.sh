#!/bin/bash
# Installation de nemOS Store
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=== Installation de nemOS Store ==="
echo ""

# Vérifier les dépendances
echo "Vérification des dépendances..."
for dep in python3 gtk3 python-gobject; do
    if ! pacman -Qi "$dep" &>/dev/null && ! pacman -Qi "python-${dep}" &>/dev/null; then
        echo "  -> Installation de $dep..."
        sudo pacman -S --noconfirm "$dep" 2>/dev/null || true
    fi
done

# Créer les répertoires
echo "Création des répertoires..."
sudo mkdir -p /usr/share/nemos-store
sudo mkdir -p /usr/share/icons/hicolor/scalable/apps/
sudo mkdir -p /usr/share/applications/

# Copier les fichiers
echo "Copie des fichiers..."
sudo cp "${SCRIPT_DIR}/nemos-store.py" /usr/bin/nemos-store
sudo chmod +x /usr/bin/nemos-store

sudo cp "${SCRIPT_DIR}/package-catalog.json" /usr/share/nemos-store/

sudo cp "${SCRIPT_DIR}/nemos-store.desktop" /usr/share/applications/

if [ -f "${SCRIPT_DIR}/nemos-store.svg" ]; then
    sudo cp "${SCRIPT_DIR}/nemos-store.svg" /usr/share/icons/hicolor/scalable/apps/nemos-store.svg
fi

# Mettre à jour le cache des icônes
echo "Mise à jour du cache des icônes..."
sudo gtk-update-icon-cache -f /usr/share/icons/hicolor/ 2>/dev/null || true
sudo update-desktop-database /usr/share/applications/ 2>/dev/null || true

echo ""
echo "=== nemOS Store installé avec succès ==="
echo "Lancez 'nemos-store' ou cherchez 'nemOS Store' dans votre menu d'applications."