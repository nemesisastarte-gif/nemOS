# Guide de construction de nemOS depuis les sources

Ce guide explique comment construire vous-même une image ISO de nemOS à partir du code source. Vous pourrez ainsi personnaliser le contenu de l'ISO, ajouter ou retirer des paquets, et créer votre propre variante de nemOS.

---

## Table des matières

- [Prérequis de construction](#prérequis-de-construction)
- [Installation des dépendances](#installation-des-dépendances)
- [Clonage du dépôt](#clonage-du-dépôt)
- [Configuration du build](#configuration-du-build)
  - [profiledef.sh — Profil de construction](#profiledefsh--profil-de-construction)
  - [packages.i686 — Liste des paquets](#packagesi686--liste-des-paquets)
  - [pacman.conf — Configuration de pacman](#pacmanconf--configuration-de-pacman)
- [Construction de l'ISO](#construction-de-liso)
- [Personnalisation du contenu de l'ISO](#personnalisation-du-contenu-de-liso)
- [Ajout de paquets personnalisés](#ajout-de-paquets-personnalisés)
- [Construction dans une machine virtuelle](#construction-dans-une-machine-virtuelle)
- [Test de l'ISO avec QEMU](#test-de-liso-avec-qemu)
- [Débogage du build](#débogage-du-build)
- [Structure des fichiers du projet](#structure-des-fichiers-du-projet)
- [Création d'une release](#création-dune-release)

---

## Prérequis de construction

### Machine hôte

La construction de nemOS doit être effectuée sur une machine tournant sous **Arch Linux** ou **Arch Linux 32**. La construction croisée depuis d'autres distributions n'est pas officiellement supportée.

> ⚠️ **Important** : Bien que nemOS cible l'architecture i686, la machine de construction peut être un système 64-bit (x86_64) ou 32-bit (i686). Sur un système 64-bit, vous devrez configurer le support multilib/i686 ou utiliser une machine virtuelle Arch Linux 32.

### Spécifications minimales de la machine de construction

| Composant | Spécification |
|---|---|
| **Système** | Arch Linux (x86_64 avec support i686) ou Arch Linux 32 |
| **Processeur** | 2 cœurs minimum (4 cœurs recommandés) |
| **Mémoire vive** | 2 Gio minimum, 4 Gio recommandés |
| **Espace disque** | 15 Gio libres minimum (10 Gio pour les fichiers de build, 5 Gio pour l'ISO finale) |
| **Connexion Internet** | Requise pour télécharger les paquets |
| **Privilèges** | Accès root (sudo) nécessaire pour exécuter mkarchiso |

### Compatibilité des machines hôtes

| Système hôte | Supporté | Notes |
|---|---|---|
| Arch Linux x86_64 | ✅ Oui | Configurez le support i686 (voir ci-dessous) |
| Arch Linux 32 i686 | ✅ Oui | Configuration native, la plus simple |
| Manjaro | ⚠️ Partiel | Peut fonctionner, mais non testé officiellement |
| Ubuntu / Debian | ❌ Non | mkarchiso nécessite des outils spécifiques à Arch |
| Fedora | ❌ Non | Pas de support pour les paquets .pkg.tar.zst |

### Configuration du support i686 sur Arch Linux x86_64

Si vous utilisez un système Arch Linux 64-bit comme machine de construction, vous devez activer le support des paquets 32-bit. Créez ou modifiez le fichier `/etc/pacman.conf` pour inclure le dépôt multilib :

```ini
[multilib]
Include = /etc/pacman.d/mirrorlist
```

Puis mettez à jour les dépôts :

```bash
sudo pacman -Sy
```

> **Note** : Arch Linux 32 utilise son propre dépôt séparé. Pour construire une ISO i686 pure, l'utilisation d'une machine virtuelle Arch Linux 32 est la méthode la plus fiable.

---

## Installation des dépendances

### Paquets principaux requis

Installez tous les paquets nécessaires à la construction de l'ISO avec la commande suivante :

```bash
sudo pacman -S --needed \
  archiso \
  arch-install-scripts \
  squashfs-tools \
  xorriso \
  mtools \
  e2fsprogs \
  dosfstools \
  libisoburn \
  zstd \
  git \
  pv \
  qemu-base
```

### Description des dépendances

| Paquet | Utilité |
|---|---|
| `archiso` | Outil principal de construction d'images ISO (fournit `mkarchiso`) |
| `arch-install-scripts` | Scripts d'installation Arch (fournit `pacstrap`, `genfstab`, `arch-chroot`) |
| `squashfs-tools` | Compression SquashFS pour le système de fichiers live |
| `xorriso` | Création de l'image ISO hybride (ISO 9660 + boot) |
| `mtools` | Manipulation de systèmes de fichiers FAT (pour EFI, si applicable) |
| `e2fsprogs` | Outils pour les systèmes de fichiers ext2/3/4 |
| `dosfstools` | Outils pour les systèmes de fichiers FAT (mkfs.fat) |
| `libisoburn` | Bibliothèque de gravure d'images ISO |
| `zstd` | Algorithme de compression rapide pour le SquashFS |
| `git` | Clonage du dépôt de sources |
| `pv` | Indicateur de progression pour les opérations longues |
| `qemu-base` | Émulateur pour tester l'ISO dans une machine virtuelle |

### Vérification de l'installation

Vérifiez que tous les outils nécessaires sont disponibles :

```bash
# Vérifier mkarchiso
which mkarchiso
mkarchiso -v

# Vérifier les autres outils
for cmd in mksquashfs xorriso mmd mkfs.ext4 git pv qemu-system-i386; do
    if command -v "$cmd" &>/dev/null; then
        echo "✅ $cmd trouvé"
    else
        echo "❌ $cmd manquant"
    fi
done
```

---

## Clonage du dépôt

Clonez le dépôt de sources de nemOS sur votre machine de construction :

```bash
# Cloner le dépôt principal
git clone https://github.com/nemesisastarte-gif/nemOS.git

# Entrer dans le répertoire du projet
cd nemOS

# Vérifier le contenu
ls -la
```

### Structure après clonage

Après le clonage, vous devriez voir la structure suivante (détaillée plus bas dans ce guide) :

```
nemOS/
├── README.md
├── LICENSE
├── CHANGELOG.md
├── .gitignore
├── build.sh              # Script de construction principal
├── services.sh           # Script de gestion des services
├── docs/
│   ├── INSTALL.md
│   └── BUILD.md
├── nem/                  # Profil de construction archiso
│   ├── profiledef.sh
│   ├── packages.x86_64
│   ├── pacman.conf
│   ├── pacman.d/
│   ├── syslinux/
│   └── airootfs/
│       ├── etc/
│       └── usr/
├── nemOS-assets/         # Ressources graphiques
│   ├── logo/
│   └── wallpapers/
├── nemOS-store/          # Magasin d'applications
├── packages/
│   └── packages.i686     # Liste des paquets de l'ISO
└── scripts/
    ├── nemos-firstboot.sh
    ├── nemos-chroot-build.sh
    └── nemos-cleanup.sh
```

---

## Configuration du build

Avant de lancer la construction, vous pouvez personnaliser plusieurs aspects de l'ISO en modifiant les fichiers de configuration du profil.

### profiledef.sh — Profil de construction

Le fichier `nem/profiledef.sh` est le fichier de configuration principal du profil archiso. Voici les paramètres modifiables :

```bash
#!/usr/bin/env bash
# Nom de l'ISO
iso_name="nemOS"

# Label du système de fichiers de l'ISO
iso_label="nemOS_$(date +%Y%m)"

# Éditeur / émetteur de l'ISO
iso_publisher="nemOS Project <https://github.com/nemesisastarte-gif/nemOS>"

# Description de l'application
iso_application="nemOS Session Live - La puissance de Linux, l'élégance de macOS"

# Version de l'ISO
iso_version="$(date +%Y.%m)"

# Répertoire d'installation dans l'ISO
install_dir="arch"

# Modes de démarrage supportés
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito')

# Architecture cible
arch="i686"

# Fichier de configuration pacman à utiliser
pacman_conf="pacman.conf"

# Type de compression du système de fichiers live
airootfs_image_type="squashfs"

# Options de compression (zstd, niveau 22, blocs de 1 Mio, 4 threads)
airootfs_image_tool_options=('-comp' 'zstd' '-Xcompression-level' '22' '-b' '1M' '-Xthreads' '4')
```

#### Paramètres importants

- **`iso_version`** : Par défaut, la version est basée sur la date (`%Y.%m`). Pour une release officielle, modifiez-la manuellement (ex : `iso_version="1.0.0"`).
- **`bootmodes`** : nemOS 1.0.0 utilise uniquement le mode BIOS Legacy via Syslinux. Pour ajouter le support UEFI, vous devrez ajouter `'uefi-x64.systemd-boot.esp'` ou `'uefi-x64.grub.esp'` et configurer les fichiers correspondants.
- **`airootfs_image_tool_options`** : Le niveau de compression zstd 22 offre la meilleure compression mais prend plus de temps. Réduisez-le à 19 ou 15 pour un build plus rapide au prix d'une ISO plus grande.
- **`arch`** : Doit rester `"i686"` pour nemOS.

### packages.i686 — Liste des paquets

Le fichier `packages/packages.i686` contient la liste de tous les paquets qui seront installés dans l'ISO. Chaque ligne est le nom d'un paquet provenant des dépôts Arch Linux 32.

#### Ajouter un paquet

Ajoutez simplement le nom du paquet à la fin du fichier, dans la catégorie appropriée :

```
## --- NAVIGATEUR WEB ---
firefox-esr
chromium    # Ajout de Chromium comme alternative
```

#### Retirer un paquet

Commentez la ligne avec `#` ou supprimez-la :

```
## --- MULTIMÉDIA ---
vlc
# mpv        # Retiré pour réduire la taille de l'ISO
```

#### Paquets provenant de l'AUR

Les paquets AUR ne peuvent pas être installés directement par mkarchiso. Pour inclure un paquet AUR :

1. Construisez le paquet AUR manuellement : `makepkg -s`
2. Placez le fichier `.pkg.tar.zst` résultant dans un répertoire local.
3. Créez un dépôt local dans le `pacman.conf` du profil (voir ci-dessous).
4. Ajoutez le nom du paquet à `packages.i686`.

### pacman.conf — Configuration de pacman

Le fichier `nem/pacman.conf` configure les dépôts de paquets utilisés pendant la construction. Il doit inclure au minimum les dépôts Arch Linux 32 :

```ini
[options]
Architecture = i686
CheckSpace
SigLevel = Required DatabaseOptional
LocalFileSigLevel = Optional

# Ajoutez ici vos dépôts locaux si nécessaire
# [nemos-local]
# SigLevel = Optional TrustAll
# Server = file:///chemin/vers/le/dépôt/local

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist
```

#### Utilisation d'un dépôt local pour les paquets personnalisés

Si vous avez construit des paquets personnalisés (icônes, thèmes, scripts), créez un dépôt local :

```bash
# Créer le répertoire du dépôt
mkdir -p ~/nemos-repo/x86_64

# Copier vos paquets .pkg.tar.zst dans ce répertoire
cp /chemin/vers/*.pkg.tar.zst ~/nemos-repo/x86_64/

# Générer la base de données du dépôt
repo-add ~/nemos-repo/x86_64/nemos-repo.db.tar.gz ~/nemos-repo/x86_64/*.pkg.tar.zst
```

Puis ajoutez le dépôt au `pacman.conf` du profil :

```ini
[nemos-repo]
SigLevel = Optional TrustAll
Server = file:///home/utilisateur/nemos-repo/x86_64
```

---

## Construction de l'ISO

Une fois la configuration terminée, lancez la construction avec le script fourni :

### Construction standard

```bash
cd /chemin/vers/nemOS
sudo ./build.sh
```

### Construction avec nettoyage préalable

Pour supprimer les artefacts d'une construction précédente avant de reconstruire :

```bash
sudo ./build.sh --clean
```

### Construction en mode verbeux

Pour obtenir des messages détaillés pendant la construction (utile pour le débogage) :

```bash
sudo ./build.sh --verbose
```

### Construction complète (nettoyage + verbeux)

```bash
sudo ./build.sh --clean --verbose
```

### Étapes de la construction

Le script `build.sh` effectue automatiquement les étapes suivantes :

1. **Vérification des privilèges root** : le script doit être exécuté avec `sudo`.
2. **Vérification des dépendances** : mkarchiso, mksquashfs, xorriso, etc.
3. **Nettoyage** (si demandé) : suppression des répertoires `/tmp/nemos-build` et `/tmp/nemos-out`.
4. **Création des répertoires de travail** : `/tmp/nemos-build` (fichiers intermédiaires) et `/tmp/nemos-out` (ISO finale).
5. **Vérification du profil** : vérification de la présence du répertoire `nem/` et de ses fichiers essentiels.
6. **Construction avec mkarchiso** :
   - Installation de tous les paquets listés dans un système de fichiers racine temporaire.
   - Exécution des scripts personnalisés (services.sh, nemos-chroot-build.sh, etc.).
   - Compression du système de fichiers en SquashFS avec zstd.
   - Création de l'image ISO avec Syslinux comme bootloader.
7. **Vérification de la taille** : si l'ISO dépasse 2 Gio, un avertissement est affiché.
8. **Génération de la somme SHA256** : un fichier `.sha256` est créé à côté de l'ISO.
9. **Rapport final** : affichage du chemin, de la taille et du SHA256 de l'ISO résultante.

### Durée de construction

La durée de construction varie considérablement selon votre matériel :

| Configuration | Durée estimée |
|---|---|
| Core 2 Duo, 2 Gio RAM, disque dur mécanique | 45 à 90 minutes |
| Core i3/i5, 4 Gio RAM, SSD | 15 à 30 minutes |
| Core i7, 8 Gio RAM, NVMe SSD | 8 à 15 minutes |
| Avec cache de paquets pacman | Réduit de 30 à 50 % |

---

## Personnalisation du contenu de l'ISO

### Ajout de fichiers personnalisés

Tout fichier placé dans le répertoire `nem/airootfs/` sera copié à la racine du système de fichiers de l'ISO, en conservant le chemin relatif.

#### Exemples

```
nem/airootfs/etc/skel/.config/openbox/rc.xml    → /etc/skel/.config/openbox/rc.xml (copié dans le home des nouveaux utilisateurs)
nem/airootfs/usr/share/nemos-assets/             → /usr/share/nemos-assets/
nem/airootfs/etc/os-release                       → /etc/os-release
```

#### Ajouter un script de démarrage personnalisé

Pour exécuter un script automatiquement au premier démarrage de la session live, placez-le dans `nem/airootfs/usr/local/bin/` et rendez-le exécutable.

### Personnalisation du bootloader Syslinux

Les fichiers de configuration de Syslinux se trouvent dans `nem/syslinux/` :

| Fichier | Description |
|---|---|
| `syslinux.cfg` | Configuration principale du bootloader |
| `archiso_sys.cfg` | Options de démarrage de la session live |
| `archiso_head.cfg` | En-tête de la configuration Syslinux |
| `archiso_tail.cfg` | Pied de page de la configuration Syslinux |
| `archiso_pxe.cfg` | Configuration pour le démarrage réseau (PXE) |

#### Modifier le message de bienvenue

Éditez `nem/syslinux/syslinux.cfg` pour modifier le titre et les options du menu de démarrage.

#### Ajouter des options de démarrage personnalisées

Vous pouvez ajouter des options de démarrage supplémentaires dans `nem/syslinux/archiso_sys.cfg` :

```ini
LABEL nemos-safe
    TEXT HELP
    Session live avec options de compatibilité maximale
    ENDTEXT
    MENU LABEL nemOS - Mode sans echec
    KERNEL /arch/boot/i686/vmlinuz-linux
    APPEND archisobasedir=arch archisolabel=%ARCHISO_LABEL% initrd=/arch/boot/i686/archiso.img nomodeset vga=normal
```

### Personnalisation de l'apparence de la session live

Le script `services.sh` à la racine du projet est exécuté dans le chroot pendant la construction. Vous pouvez l'utiliser pour :

- Copier des fichiers de configuration personnalisés.
- Appliquer des thèmes et des fonds d'écran.
- Configurer des services.
- Préconfigurer des applications.

Consultez le fichier `services.sh` existant pour voir les personnalisations déjà appliquées.

---

## Ajout de paquets personnalisés

### Format PKGBUILD

Pour créer un paquet personnalisé pour nemOS, utilisez le format standard PKGBUILD d'Arch Linux. Voici un exemple complet pour un paquet de thème personnalisé :

```bash
# Maintainer : Votre Nom <votre@email.com>
pkgname=nemos-mon-theme
pkgver=1.0.0
pkgrel=1
pkgdesc="Thème personnalisé pour nemOS"
arch=('i686' 'x86_64')
url="https://github.com/votre-compte/nemos-mon-theme"
license=('GPL-3.0')
depends=('gtk-engine-murrine' 'gtk-engines')
source=("MonTheme.tar.gz")
sha256sums=('abcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890')

package() {
    # Thème GTK
    install -d "$pkgdir/usr/share/themes/MonTheme"
    cp -r src/gtk-2.0 "$pkgdir/usr/share/themes/MonTheme/"
    cp -r src/gtk-3.0 "$pkgdir/usr/share/themes/MonTheme/"

    # Thème Openbox
    install -d "$pkgdir/usr/share/themes/MonTheme/openbox-3"
    cp -r src/openbox-3/* "$pkgdir/usr/share/themes/MonTheme/openbox-3/"

    # Icônes
    install -d "$pkgdir/usr/share/icons/MonTheme"
    cp -r src/icons/* "$pkgdir/usr/share/icons/MonTheme/"
}
```

### Construction du paquet

```bash
# Créer un répertoire temporaire
mkdir -p ~/build/nemos-mon-theme && cd ~/build/nemos-mon-theme

# Placer le PKGBUILD et les sources dans ce répertoire

# Construire le paquet
makepkg -s

# Le fichier .pkg.tar.zst résultant peut être ajouté à un dépôt local
# (voir la section sur les dépôts locaux ci-dessus)
```

### Inclure le paquet dans l'ISO

1. Construisez le paquet (voir ci-dessus).
2. Ajoutez-le au dépôt local.
3. Ajoutez le nom du paquet (`nemos-mon-theme`) dans `packages/packages.i686`.

---

## Construction dans une machine virtuelle

Si vous n'avez pas de machine Arch Linux physique, vous pouvez construire nemOS dans une machine virtuelle. C'est aussi une bonne méthode pour garantir un environnement de construction propre et reproductible.

### Création de la VM avec QEMU

```bash
# Créer un disque virtuel de 30 Gio
qemu-img create -f qcow2 nemos-build-vm.qcow2 30G

# Télécharger l'image ISO d'installation d'Arch Linux 32
wget https://mirror.archlinux32.org/archlinux32/iso/latest/archlinux32-latest-i686.iso

# Lancer la VM avec l'ISO d'installation
qemu-system-i386 \
    -m 4096 \
    -smp 2 \
    -drive file=nemos-build-vm.qcow2,format=qcow2 \
    -cdrom archlinux32-latest-i686.iso \
    -boot d \
    -net nic -net user
```

### Installation d'Arch Linux 32 dans la VM

Suivez le guide d'installation d'Arch Linux 32 standard. Assurez-vous d'installer les dépendances de construction (voir la section « Installation des dépendances ») et de configurer l'accès SSH pour faciliter le transfert de fichiers entre la VM et votre machine hôte.

### Transfert des sources dans la VM

```bash
# Depuis la machine hôte : copier les sources de nemOS dans la VM
scp -r /chemin/vers/nemOS utilisateur@ip-de-la-vm:/home/utilisateur/

# Ou utiliser git directement dans la VM
git clone https://github.com/nemesisastarte-gif/nemOS.git
```

### Conseils pour la construction en VM

- **Mémoire** : Allouez au moins 4 Gio de mémoire vive à la VM. La construction consomme beaucoup de RAM pendant la compression SquashFS.
- **Processeur** : Allouez au moins 2 cœurs virtuels pour accélérer la compilation et la compression.
- **Disque** : Prévoyez au moins 20 Gio pour le système + les fichiers de construction.
- **Dossier partagé** : Utilisez un montage SSHFS ou un dossier partagé pour récupérer facilement l'ISO finale sur la machine hôte.
- **Snapshot** : Prenez un snapshot de la VM après l'installation d'Arch Linux 32 pour pouvoir recommencer rapidement en cas de problème.

---

## Test de l'ISO avec QEMU

Après la construction, testez l'ISO dans une machine virtuelle avant de la flasher sur une clé USB.

### Démarrage basique

```bash
# Démarrer nemOS dans QEMU avec 1 Gio de RAM
qemu-system-i386 \
    -m 1024 \
    -cdrom /tmp/nemos-out/nemOS-*.iso \
    -boot d
```

### Test avec des spécifications réalistes (vieux PC)

Pour simuler les conditions d'un vieux PC :

```bash
# Simulation d'un netbook avec 512 Mio de RAM et un seul cœur
qemu-system-i386 \
    -m 512 \
    -smp 1 \
    -cdrom /tmp/nemos-out/nemOS-*.iso \
    -boot d \
    -vga std \
    -audio alsa
```

### Test de l'installation

Pour tester le processus d'installation complet :

```bash
# Créer un disque virtuel de 20 Gio
qemu-img create -f qcow2 nemos-test-disk.qcow2 20G

# Démarrer avec l'ISO et le disque
qemu-system-i386 \
    -m 2048 \
    -smp 2 \
    -cdrom /tmp/nemos-out/nemOS-*.iso \
    -drive file=nemos-test-disk.qcow2,format=qcow2 \
    -boot d
```

Lancez l'installateur Calamares dans la VM pour vérifier que le processus d'installation fonctionne correctement.

### Vérification post-installation

Après l'installation dans la VM, redémarrez sans l'ISO pour vérifier que le système installé fonctionne :

```bash
qemu-system-i386 \
    -m 2048 \
    -drive file=nemos-test-disk.qcow2,format=qcow2 \
    -boot c
```

### Test avec VirtualBox

Si vous préférez VirtualBox :

1. Ouvrez VirtualBox et créez une nouvelle machine (type « Linux », version « Arch Linux (32-bit) »).
2. Allouez 1024 Mio de mémoire vive et un disque dur de 20 Gio.
3. Dans les paramètres de la VM, allez dans « Stockage » → « Contrôleur IDE » → « Vide » → cliquez sur l'icône de disque et sélectionnez l'ISO nemOS.
4. Cochez « Live CD/DVD » dans le type de média.
5. Démarrez la VM.

---

## Débogage du build

### Erreur « mkarchiso: command not found »

**Cause** : Le paquet `archiso` n'est pas installé.

**Solution** :
```bash
sudo pacman -S archiso
```

### Erreur « permission denied » lors de la construction

**Cause** : Le script n'est pas exécuté avec les privilèges root.

**Solution** :
```bash
sudo ./build.sh
```

### Erreur « cannot find package ... in repositories »

**Cause** : Un paquet listé dans `packages.i686` n'existe pas dans les dépôts configurés.

**Solution** :
1. Vérifiez que le paquet existe dans les dépôts Arch Linux 32 : `pacman -Ss nom-du-paquet`
2. Vérifiez que votre `pacman.conf` du profil pointe vers les bons dépôts.
3. Si le paquet a été renommé, mettez à jour le nom dans `packages.i686`.
4. Si le paquet n'existe qu'en AUR, construisez-le manuellement et ajoutez-le à un dépôt local.

### Erreur « not enough disk space »

**Cause** : L'espace disque disponible est insuffisant pour la construction.

**Solution** :
- Libérez de l'espace sur la machine de construction : `sudo pacman -Sc` (vider le cache des paquets).
- Modifiez les variables `WORKDIR` et `OUTDIR` dans `build.sh` pour pointer vers un autre disque avec plus d'espace.
- Réduisez le nombre de paquets dans `packages.i686` pour créer une ISO plus petite.

### Erreur « failed to create squashfs »

**Cause** : Problème de permissions, d'espace disque ou de mémoire pendant la compression.

**Solution** :
- Vérifiez l'espace disponible : `df -h /tmp`
- Réduisez le niveau de compression dans `profiledef.sh` : changez `'22'` en `'19'` ou `'15'`.
- Réduisez la taille du bloc : changez `'-b' '1M'` en `'-b' '256K'`.
- Vérifiez les journaux : `cat /tmp/nemos-build/build.log`

### L'ISO est corrompue ou ne démarre pas

**Cause** : La construction s'est terminée mais l'ISO ne fonctionne pas correctement.

**Solution** :
1. Vérifiez la somme SHA256 : `sha256sum /tmp/nemos-out/nemOS-*.iso`
2. Testez l'ISO avec QEMU (voir la section ci-dessus).
3. Vérifiez la configuration Syslinux : `cat nem/syslinux/syslinux.cfg`
4. Essayez de reconstruire avec `sudo ./build.sh --clean`

### Erreur de clé GPG pendant la construction

**Cause** : Les clés de signature des dépôts Arch Linux 32 ne sont pas à jour.

**Solution** :
```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux32
sudo pacman -Sy archlinux32-keyring
```

---

## Structure des fichiers du projet

Voici la structure complète du projet nemOS avec une explication de chaque répertoire et fichier :

```
nemOS/
│
├── README.md                    # Documentation principale du projet
├── LICENSE                      # Licence GPL-3.0
├── CHANGELOG.md                 # Journal des modifications
├── .gitignore                   # Fichiers ignorés par Git
│
├── build.sh                     # Script principal de construction de l'ISO
│                                 # Vérifie les dépendances, appelle mkarchiso,
│                                 # génère les sommes SHA256
│
├── services.sh                  # Script exécuté dans le chroot pendant le build
│                                 # Configure les services, copie les fichiers,
│                                 # applique les personnalisations
│
├── docs/                        # Documentation supplémentaire
│   ├── INSTALL.md               # Guide d'installation
│   └── BUILD.md                 # Ce fichier — guide de construction
│
├── nem/                         # Profil de construction archiso
│   │
│   ├── profiledef.sh            # Configuration du profil (nom, version, arch,
│   │                             # bootmodes, compression)
│   │
│   ├── pacman.conf              # Configuration pacman pour la construction
│   │                             # (dépôts Arch Linux 32, options de signature)
│   │
│   ├── pacman.d/                # Liste de miroirs pour pacman
│   │   ├── mirrorlist           # Miroirs principaux Arch Linux 32
│   │   └── 1mirrorlist          # Miroirs de secours
│   │
│   ├── syslinux/                # Configuration du bootloader Syslinux
│   │   ├── syslinux.cfg         # Point d'entrée principal du bootloader
│   │   ├── archiso_head.cfg     # En-tête commun (défauts, séquence ESC)
│   │   ├── archiso_sys.cfg      # Configuration de la session live
│   │   ├── archiso_sys-linux.cfg# Options du noyau Linux pour la session live
│   │   ├── archiso_tail.cfg     # Fin de la configuration
│   │   ├── archiso_pxe.cfg      # Configuration PXE (démarrage réseau)
│   │   └── archiso_pxe-linux.cfg# Options du noyau pour PXE
│   │
│   └── airootfs/                # Arborescence copiée dans l'ISO
│       ├── etc/                 # Fichiers de configuration système
│       │   ├── os-release       # Informations d'identification du système
│       │   └── lsb-release      # Informations LSB
│       │
│       ├── environment          # Variables d'environnement par défaut
│       │
│       └── usr/                 # Fichiers système (thèmes, scripts)
│           └── share/
│               └── themes/
│                   └── nemOS-Dark/
│                       ├── gtk-2.0/gtkrc     # Thème GTK2
│                       └── gtk-3.0/
│                           ├── gtk.css         # Thème GTK3 (clair)
│                           └── gtk-dark.css    # Thème GTK3 (sombre)
│
├── packages/                    # Configuration des paquets
│   └── packages.i686            # Liste des paquets à installer dans l'ISO
│                                 # Organisée par catégorie avec commentaires
│
├── scripts/                     # Scripts utilitaires
│   ├── nemos-firstboot.sh       # Assistant de premier démarrage (exécuté
│   │                             # après l'installation)
│   ├── nemos-chroot-build.sh    # Script exécuté dans le chroot pendant
│   │                             # la construction de l'ISO
│   └── nemos-cleanup.sh         # Outil de nettoyage du système
│
├── nemOS-assets/                # Ressources graphiques du projet
│   ├── logo/
│   │   ├── nemos-logo.svg       # Logo principal de nemOS (SVG)
│   │   └── nemos-logo-rounded.svg # Logo avec coins arrondis
│   │
│   └── wallpapers/
│       ├── nemos-default.png    # Fond d'écran par défaut
│       ├── nemos-dark.png       # Fond d'écran sombre
│       ├── nemos-sunset.png     # Fond d'écran coucher de soleil
│       ├── nemos-ocean.png      # Fond d'écran océan
│       ├── nemos-minimal.png    # Fond d'écran minimaliste
│       └── generate-wallpapers.py # Script de génération des fonds d'écran
│
└── nemOS-store/                 # Magasin d'applications nemOS Store
    ├── nemos-store.py           # Application principale (Python/PyQt5)
    ├── nemos-store.desktop      # Fichier .desktop pour le menu d'applications
    ├── nemos-store.svg          # Icône du magasin
    ├── package-catalog.json     # Catalogue des applications disponibles
    └── install-store.sh         # Script d'installation du magasin
```

---

## Création d'une release

Une fois l'ISO construite et testée, voici comment créer une release officielle sur GitHub.

### 1. Mettre à jour le numéro de version

Avant de créer la release, mettez à jour le numéro de version dans les fichiers suivants :

```bash
# profiledef.sh
sed -i 's/iso_version=.*/iso_version="1.0.0"/' nem/profiledef.sh

# os-release
sed -i 's/VERSION=.*/VERSION="1.0.0"/' nem/airootfs/etc/os-release
sed -i 's/VERSION_ID=.*/VERSION_ID="1.0.0"/' nem/airootfs/etc/os-release

# CHANGELOG.md
# Ajoutez une nouvelle section en haut du fichier (voir format dans CHANGELOG.md)
```

### 2. Construire l'ISO finale

```bash
sudo ./build.sh --clean --verbose
```

### 3. Vérifier l'ISO

```bash
# Vérifier l'intégrité
sha256sum -c /tmp/nemos-out/nemOS-*.sha256

# Vérifier la taille
ls -lh /tmp/nemos-out/

# Tester dans QEMU
qemu-system-i386 -m 1024 -cdrom /tmp/nemos-out/nemOS-*.iso -boot d
```

### 4. Créer un tag Git

```bash
git add -A
git commit -m "release: nemOS v1.0.0"
git tag -a v1.0.0 -m "nemOS version 1.0.0 — Première version stable"
git push origin main --tags
```

### 5. Créer la release GitHub

1. Rendez-vous sur la page [Releases](https://github.com/nemesisastarte-gif/nemOS/releases) du dépôt.
2. Cliquez sur « Draft a new release ».
3. Sélectionnez le tag `v1.0.0`.
4. Remplissez le titre : « nemOS v1.0.0 — Première version stable ».
5. Rédigez les notes de version (copiez la section pertinente du CHANGELOG.md).
6. Glissez-déposez les fichiers suivants :
   - `nemOS-1.0.0-i686.iso`
   - `nemOS-1.0.0-i686.iso.sha256`
7. Cochez « Set as the latest release ».
8. Cliquez sur « Publish release ».

### 6. Annoncer la release

Partagez la nouvelle release sur les canaux de communication du projet (réseaux sociaux, forums, etc.) en incluant :

- Le lien vers la release
- Les nouveautés principales
- Les liens vers le guide d'installation
- Les problèmes connus (le cas échéant)

---

<div align="center">

  **Bonne construction !**

  [Retour au README](../README.md) · [Guide d'installation](INSTALL.md) · [Signaler un bug](https://github.com/nemesisastarte-gif/nemOS/issues)

</div>