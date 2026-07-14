# Guide d'installation de nemOS

Ce guide détaille toutes les étapes pour installer nemOS sur votre ordinateur, depuis le téléchargement de l'image ISO jusqu'à la configuration post-installation. Que vous soyez débutant ou utilisateur avancé, ce guide vous accompagnera à chaque étape.

---

## Table des matières

- [Prérequis matériels](#prérequis-matériels)
- [Méthodes de création de la clé USB](#méthodes-de-création-de-la-clé-usb)
  - [Méthode 1 : dd (Linux / macOS)](#méthode-1--dd-linux--macos)
  - [Méthode 2 : Ventoy (recommandé pour les tests multiples)](#méthode-2--ventoy-recommandé-pour-les-tests-multiples)
  - [Méthode 3 : Rufus (Windows)](#méthode-3--rufus-windows)
- [Démarrage sur la clé USB](#démarrage-sur-la-clé-usb)
- [Installation avec Calamares](#installation-avec-calamares)
  - [Étape 1 : Bienvenue](#étape-1--bienvenue)
  - [Étape 2 : Localisation](#étape-2--localisation)
  - [Étape 3 : Clavier](#étape-3--clavier)
  - [Étape 4 : Partitionnement](#étape-4--partitionnement)
  - [Étape 5 : Utilisateur](#étape-5--utilisateur)
  - [Étape 6 : Résumé](#étape-6--résumé)
  - [Étape 7 : Installation](#étape-7--installation)
  - [Étape 8 : Terminé](#étape-8--terminé)
- [Installation en mode texte](#installation-en-mode-texte)
- [Post-installation](#post-installation)
- [Configuration réseau](#configuration-réseau)
- [Installation de pilotes supplémentaires](#installation-de-pilotes-supplémentaires)
- [Mise à jour du système](#mise-à-jour-du-système)
- [Configuration du système](#configuration-du-système)
- [Résolution des problèmes d'installation](#résolution-des-problèmes-dinstallation)

---

## Prérequis matériels

Avant de procéder à l'installation, vérifiez que votre ordinateur respecte les prérequis suivants.

### Configuration minimale absolue

| Composant | Spécification |
|---|---|
| **Processeur** | Intel Pentium III ou supérieur (architecture i686), 600 MHz minimum |
| **Mémoire vive (RAM)** | 512 Mio (1 Gio fortement recommandé pour une utilisation confortable) |
| **Stockage** | 8 Gio d'espace libre sur le disque dur |
| **Carte vidéo** | Compatible VESA avec au moins 8 Mio de mémoire vidéo |
| **Amorçage** | Support BIOS Legacy (le mode UEFI pur n'est pas encore supporté) |
| **Clé USB** | 2 Gio minimum pour créer le support d'installation |

### Configuration recommandée pour une utilisation quotidienne

| Composant | Spécification |
|---|---|
| **Processeur** | Intel Pentium 4 (2 GHz+), Intel Atom N270/N450, ou AMD Athlon XP/64 |
| **Mémoire vive (RAM)** | 2 Gio ou plus |
| **Stockage** | 20 Gio ou plus (un SSD améliore considérablement les performances) |
| **Carte vidéo** | Intel GMA 950/3100, ATI Radeon X1200/HD2400, ou NVIDIA série 6/7 |
| **Amorçage** | BIOS avec support de démarrage USB 2.0 |
| **Clé USB** | 4 Gio minimum |

### Vérification du processeur

Pour vérifier que votre processeur est compatible 32-bit (i686), vous pouvez :

- **Sous Windows** : Ouvrez `Informations système` (touche Windows + Pause) et regardez le type de système. S'il indique « Système d'exploitation 32 bits » ou « Processeur x86 », votre ordinateur est compatible.
- **Sous Linux** : Exécutez la commande `uname -m`. Si le résultat est `i686`, `i386` ou `x86`, votre processeur est 32-bit.
- **Sur macOS** : Cliquez sur « À propos de ce Mac » → « Plus d'infos » → « Rapport système » → « Processeur ». Les Mac Intel sont tous 64-bit depuis 2006.

### Notes sur le BIOS/UEFI

nemOS 1.0.0 utilise un bootloader **Syslinux** en mode **BIOS Legacy**. Cela signifie :

- ✅ Les ordinateurs avec BIOS traditionnel fonctionnent directement.
- ✅ Les ordinateurs avec UEFI configuré en mode « CSM » (Compatibility Support Module) / « Legacy Boot » fonctionnent.
- ❌ Les ordinateurs avec UEFI pur (sans CSM) ne peuvent pas démarrer nemOS 1.0.0. Le support UEFI est prévu pour une future version.

Pour vérifier et modifier le mode de démarrage de votre UEFI, accédez au firmware (généralement en appuyant sur F2, F12, Del ou Esc au démarrage) et cherchez l'option « Boot Mode » ou « CSM ».

---

## Méthodes de création de la clé USB

Une fois l'image ISO téléchargée et vérifiée (voir le [README.md](../README.md#téléchargement)), vous devez la flasher sur une clé USB. Voici trois méthodes détaillées.

> ⚠️ **Avertissement** : L'opération de flashage effacera **toutes les données** présentes sur la clé USB. Sauvegardez vos données avant de procéder.

### Méthode 1 : `dd` (Linux / macOS)

La méthode `dd` est la plus simple et la plus fiable sous Linux et macOS. Elle écrit l'image ISO bit par bit sur la clé USB.

#### Identification de la clé USB

```bash
# Sous Linux — lister les disques
lsblk -o NAME,SIZE,TYPE,MOUNTPOINT

# Sous macOS — lister les disques
diskutil list
```

Repérez votre clé USB dans la liste. Sous Linux, elle apparaît généralement sous le nom `/dev/sdX` (où `X` est une lettre comme `b`, `c`, `d`). Sous macOS, elle apparaît sous `/dev/diskN` (où `N` est un numéro).

#### Démontage de la clé USB

```bash
# Sous Linux
sudo umount /dev/sdX1

# Sous macOS
sudo diskutil unmountDisk /dev/diskN
```

#### Flashage de l'ISO

```bash
# Sous Linux
sudo dd if=/chemin/vers/nemOS-1.0.0-i686.iso of=/dev/sdX bs=4M status=progress && sync

# Sous macOS
sudo dd if=/chemin/vers/nemOS-1.0.0-i686.iso of=/dev/rdiskN bs=4m status=progress && sync
```

**Note sur macOS** : utilisez `/dev/rdiskN` (raw disk) au lieu de `/dev/diskN` pour une écriture nettement plus rapide. Le `sync` final garantit que toutes les données sont écrites avant de retirer la clé.

### Méthode 2 : Ventoy (recommandé pour les tests multiples)

[Ventoy](https://www.ventoy.net/) est un outil qui transforme votre clé USB en un lecteur multiboot. Vous pouvez copier plusieurs fichiers ISO sur la clé et choisir celui à démarrer au lancement.

#### Installation de Ventoy

1. Téléchargez Ventoy depuis [ventoy.net](https://www.ventoy.net/fr/download.html).
2. Décompressez l'archive.
3. Lancez l'interface graphique (`VentoyGUI.x86_64` sous Linux, `Ventoy2Disk.exe` sous Windows).
4. Sélectionnez votre clé USB dans la liste.
5. Cliquez sur « Installer ».

#### Copie de l'ISO

Après l'installation de Ventoy, votre clé USB apparaît comme un lecteur normal dans votre gestionnaire de fichiers. Copiez simplement le fichier `nemOS-1.0.0-i686.iso` à la racine de la clé USB.

#### Démarrage

Au démarrage de l'ordinateur, sélectionnez la clé USB dans le menu de démarrage. Ventoy affichera une liste des ISO disponibles. Sélectionnez `nemOS-1.0.0-i686.iso` pour démarrer.

**Avantages de Ventoy :** pas besoin de reflasher la clé pour tester une nouvelle version de nemOS, il suffit de remplacer le fichier ISO.

### Méthode 3 : Rufus (Windows)

[Rufus](https://rufus.ie/) est l'outil de création de clé USB amorçable le plus populaire sous Windows.

#### Étapes

1. Téléchargez Rufus depuis [rufus.ie](https://rufus.ie/fr/).
2. Insérez votre clé USB.
3. Lancez Rufus (aucune installation nécessaire).
4. Dans le champ « Périphérique », sélectionnez votre clé USB.
5. Dans le champ « Type de démarrage », cliquez sur « SÉLECTIONNER » et choisissez le fichier `nemOS-1.0.0-i686.iso`.
6. Vérifiez les paramètres :
   - **Schéma de partition** : MBR
   - **Système cible** : BIOS ou UEFI-CSM
   - **Système de fichiers** : FAT32
   - **Taille de cluster** : Par défaut
7. Cliquez sur « DÉMARRER ».
8. Si Rufus demande s'il doit écrire en mode « Image ISO » ou « Mode DD », choisissez le **mode Image ISO** (recommandé).
9. Attendez que l'opération se termine.

---

## Démarrage sur la clé USB

Une fois la clé USB préparée, insérez-la dans l'ordinateur cible et redémarrez-le.

### Accès au menu de démarrage

Au démarrage, vous devrez indiquer à votre ordinateur de booter sur la clé USB. Selon le fabricant de votre ordinateur, appuyez sur l'une des touches suivantes :

| Fabricant | Touche de démarrage |
|---|---|
| Acer | F12, F9, Esc |
| Asus | Esc, F8 |
| Dell | F12 |
| HP | F9, Esc |
| Lenovo | F12, Fn+F12 |
| Samsung | F2, F12, Esc |
| Toshiba | F12 |
| Autres | F12, F11, F8, Esc |

Si aucune touche ne fonctionne, accédez au BIOS (généralement F2 ou Del) et modifiez l'ordre de démarrage pour placer l'USB en premier.

### Menu Syslinux de nemOS

Une fois l'ISO chargée, vous verrez le menu de démarrage Syslinux avec les options suivantes :

```
  nemOS - Session Live (par défaut)
  nemOS - Session Live (mode sans échec / nomodeset)
  Memtest86+ - Test de la mémoire
```

- **Session Live (par défaut)** : démarre le système complet en mémoire vive. Utilisez cette option pour tester nemOS ou lancer l'installateur.
- **Session Live (nomodeset)** : démarre sans les pilotes graphiques propriétaires. Utilisez cette option si vous avez des problèmes d'affichage.
- **Memtest86+** : outil de diagnostic de la mémoire vive. Utilisez-le si vous suspectez des barrettes mémoire défectueuses.

Sélectionnez « Session Live (par défaut) » avec les flèches du clavier et appuyez sur Entrée.

---

## Installation avec Calamares

Une fois la session live chargée, vous arrivez sur le bureau de nemOS. L'installateur Calamares est accessible via l'icône « Installer le système » dans le dock Plank.

`[Capture d'écran : Bureau live de nemOS avec l'icône de l'installateur Calamares dans le dock]`

### Étape 1 : Bienvenue

La première page de Calamares vous souhaite la bienvenue et vous demande de sélectionner la langue de l'installation. Sélectionnez **« Français »** dans la liste déroulante. L'interface entière de l'installateur bascule en français.

`[Capture d'écran : Page de bienvenue de Calamares avec la sélection de la langue française]`

Cliquez sur **« Suivant »**.

### Étape 2 : Localisation

Cette page vous permet de configurer la zone géographique et le fuseau horaire.

1. **Région** : sélectionnez « Europe ».
2. **Zone** : sélectionnez « France » (ou votre pays).
3. Le fuseau horaire est automatiquement défini sur « Europe/Paris » (ou l'équivalent pour votre pays).

`[Capture d'écran : Page de localisation avec la carte du monde et la sélection Europe/France]`

Cliquez sur **« Suivant »**.

### Étape 3 : Clavier

Sélectionnez la disposition du clavier adaptée à votre matériel.

1. **Modèle** : choisissez le modèle de votre clavier. Si vous ne le connaissez pas, laissez « Clavier générique 105 touches (intl) ».
2. **Disposition** : sélectionnez « Français ».
3. **Variante** : choisissez « Français (variante) » ou « Français (AZERTY) ».
4. Testez votre clavier dans la zone de texte prévue à cet effet pour vérifier que les touches correspondent bien.

`[Capture d'écran : Page de sélection du clavier avec la zone de test]`

Cliquez sur **« Suivant »**.

### Étape 4 : Partitionnement

C'est l'étape la plus importante. Calamares propose plusieurs options de partitionnement.

#### Option A : Partitionnement automatique (recommandé pour les débutants)

1. Sélectionnez **« Effacer le disque »**.
2. Choisissez le disque sur lequel installer nemOS dans la liste.
3. **⚠️ AVERTISSEMENT : toutes les données sur ce disque seront supprimées.**
4. Sélectionnez le système de fichiers : **ext4** (recommandé) ou **btrfs** (pour les fonctionnalités avancées de snapshots).
5. Cochez ou décochez l'option de chiffrement LUKS si vous souhaitez chiffrer votre disque.

#### Option B : Partitionnement manuel (avancé)

Sélectionnez **« Manuel »** pour accéder à l'éditeur de partitions graphique. Vous pouvez alors :

1. Sélectionner un disque existant.
2. Créer, modifier ou supprimer des partitions.
3. Définir les points de montage :

| Point de montage | Système de fichiers | Taille recommandée | Note |
|---|---|---|---|
| `/` (racine) | ext4 | Minimum 8 Gio, recommandé 20 Gio | Partition principale |
| `/home` | ext4 | Le reste de l'espace | Données utilisateur |
| `swap` | linux-swap | Égale à la RAM, max 4 Gio | Fichier d'échange |
| `/boot` | ext2 | 200-500 Mio | Optionnel |

#### Option C : Installer à côté d'un système existant

Si votre disque contient déjà Windows ou un autre système d'exploitation, vous pouvez choisir **« Installer à côté de Windows »** (si disponible). Calamares redimensionnera automatiquement la partition existante pour créer de l'espace pour nemOS.

> 💡 **Conseil** : Avant tout partitionnement, sauvegardez vos données importantes sur un support externe. Même avec le partitionnement automatique, un incident est toujours possible.

`[Capture d'écran : Page de partitionnement de Calamares avec les options disponibles]`

Cliquez sur **« Suivant »**.

### Étape 5 : Utilisateur

Configurez votre compte utilisateur et le mot de passe de root.

1. **Nom complet** : votre nom d'affichage (ex : « Jean Dupont »).
2. **Nom d'utilisateur** : votre identifiant de connexion, en minuscules sans espaces (ex : « jean »).
3. **Mot de passe** : choisissez un mot de passe fort (minimum 8 caractères, mélange de lettres, chiffres et caractères spéciaux).
4. **Confirmation du mot de passe** : resaisissez le même mot de passe.
5. **Mot de passe de l'administrateur (root)** : choisissez un mot de passe root. Vous pouvez utiliser le même que votre utilisateur ou un mot de passe différent.
6. **Nom de l'ordinateur** : le nom d'hôte qui identifiera votre machine sur le réseau (ex : « pc-jean »).
7. Cochez **« Se connecter automatiquement »** si vous ne souhaitez pas saisir votre mot de passe à chaque démarrage (déconseillé sur un ordinateur partagé).

`[Capture d'écran : Page de création de l'utilisateur dans Calamares]`

Cliquez sur **« Suivant »**.

### Étape 6 : Résumé

Calamares affiche un résumé de toutes les options que vous avez sélectionnées. Vérifiez attentivement :

- La langue et la disposition du clavier
- Le fuseau horaire
- Le schéma de partitionnement
- Le nom d'utilisateur et le nom de l'ordinateur

Si tout est correct, cochez la case « Je confirme que je souhaite procéder à l'installation. » et cliquez sur **« Installer »**.

`[Capture d'écran : Page de résumé de Calamares avant le lancement de l'installation]`

### Étape 7 : Installation

Calamares procède à l'installation. Cette étape peut durer de 5 à 30 minutes selon la vitesse de votre disque dur et la quantité de paquets à installer. Une barre de progression et un journal détaillé vous indiquent l'avancement.

Pendant l'installation, vous pouvez consulter le journal en cliquant sur le bouton « Afficher le journal » pour voir les opérations en cours (copie des fichiers, installation des paquets, configuration du bootloader, etc.).

**Ne coupez pas l'alimentation et ne redémarrez pas l'ordinateur pendant cette étape.**

`[Capture d'écran : Barre de progression de l'installation Calamares]`

### Étape 8 : Terminé

Une fois l'installation terminée, Calamares affiche un message de confirmation. Cliquez sur **« Terminer »** pour redémarrer l'ordinateur.

N'oubliez pas de **retirer la clé USB** au moment du redémarrage pour que l'ordinateur démarre sur le disque dur nouvellement installé.

`[Capture d'écran : Écran de fin de l'installation Calamares]`

---

## Installation en mode texte

Si vous ne pouvez pas utiliser l'installateur graphique (problème d'affichage, serveur sans écran, préférence personnelle), vous pouvez installer nemOS en mode texte depuis la session live.

### 1. Préparer les partitions

```bash
# Lister les disques
lsblk

# Partitionner le disque (remplacez /dev/sda par votre disque)
sudo fdisk /dev/sda
# Dans fdisk : o (nouvelle table), n (nouvelle partition), w (écrire)
```

### 2. Formater et monter les partitions

```bash
# Formater la partition racine
sudo mkfs.ext4 /dev/sda1

# Monter la partition
sudo mount /dev/sda1 /mnt

# Créer et formater le swap (si applicable)
sudo mkswap /dev/sda2
sudo swapon /dev/sda2
```

### 3. Installer le système de base

```bash
# Installer les paquets de base et le noyau
sudo pacstrap /mnt base base-devel linux32 linux-firmware

# Générer le fstab
sudo genfstab -U /mnt >> /mnt/etc/fstab
```

### 4. Configurer le système

```bash
# Entrer dans le système installé
sudo arch-chroot /mnt

# Définir la locale
echo "fr_FR.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=fr_FR.UTF-8" > /etc/locale.conf

# Définir le fuseau horaire
ln -sf /usr/share/zoneinfo/Europe/Paris /etc/etc/localtime
hwclock --systohc

# Définir le nom d'hôte
echo "mon-nemos-pc" > /etc/hostname

# Créer l'utilisateur
useradd -m -G wheel,audio,video,storage -s /bin/bash monuser
passwd monuser

# Installer le bootloader
pacman -S syslinux
syslinux-install_update -i -a -m

# Sortir du chroot et démonter
exit
sudo umount -R /mnt
```

### 5. Redémarrer

```bash
sudo reboot
```

---

## Post-installation

Après le premier démarrage de nemOS installé sur le disque dur, le script de premier démarrage (`nemos-firstboot`) se lance automatiquement. Ce script interactif vous guide à travers les étapes de configuration initiale :

1. **Nom d'hôte** : défini lors de l'installation, modifiable ici.
2. **Réseau** : connexion Wi-Fi ou vérification de la connexion filaire.
3. **Locale** : vérification de la configuration française.
4. **Fichier fstab** : vérification et correction si nécessaire.
5. **TRIM (SSD)** : activation automatique si un SSD est détecté.
6. **Utilisateur** : création du compte utilisateur avec les bons groupes et permissions sudo.
7. **Services** : activation de NetworkManager, CUPS, Bluetooth, etc.
8. **Thème** : application du thème visuel nemOS (GTK, Openbox, dock).
9. **Fonds d'écran** : copie des fonds d'écran dans votre répertoire personnel.
10. **Flatpak** : proposition d'installation du support Flatpak.

> 💡 Si vous sautez le premier démarrage ou si vous souhaitez le relancer, vous pouvez exécuter `sudo nemos-firstboot` dans un terminal.

---

## Configuration réseau

### Wi-Fi

```bash
# Lister les réseaux Wi-Fi disponibles
nmcli dev wifi list

# Se connecter à un réseau
nmcli dev wifi connect "NomDuReseau" password "VotreMotDePasse"

# Vérifier la connexion
nmcli connection show
ip addr show
ping -c 4 archlinux.org
```

### Interface graphique

L'applet réseau dans la barre Tint2 (en haut à droite) permet de gérer les connexions Wi-Fi en cliquant sur l'icône. Vous pouvez également utiliser l'outil graphique NetworkManager :

```bash
nm-connection-editor
```

### Mode texte (nmtui)

Si l'interface graphique n'est pas disponible, utilisez `nmtui` :

```bash
nmtui
```

Une interface en mode texte vous permet de naviguer avec les flèches du clavier pour activer une connexion, se connecter à un réseau Wi-Fi ou créer un profil de connexion.

### Ethernet

Si vous utilisez un câble Ethernet, la connexion est généralement automatique grâce à NetworkManager et dhcpcd. Vérifiez avec :

```bash
ip addr show
ping -c 4 archlinux.org
```

---

## Installation de pilotes supplémentaires

### Pilotes Wi-Fi

Les pilotes Wi-Fi les plus courants sont inclus dans le noyau Linux. Cependant, certaines cartes nécessitent des pilotes supplémentaires :

```bash
# Cartes Broadcom (très courantes dans les portables anciens)
sudo pacman -S broadcom-wl
sudo modprobe wl

# Cartes Realtek (certains modèles)
sudo pacman -S rtl8812au-dkms linux-headers  # si disponible en i686

# Cartes Ralink
# Généralement supportées par le noyau, pas de paquet supplémentaire nécessaire
```

### Pilotes vidéo

nemOS inclut par défaut les pilotes open source pour les cartes Intel, AMD et NVIDIA. Pour les cartes spécifiques :

```bash
# Pilotes Intel (généralement inclus, mais pour forcer la version)
sudo pacman -S xf86-video-intel mesa

# Pilotes AMD (open source — recommandé)
sudo pacman -S xf86-video-ati mesa

# Pilotes NVIDIA (anciens modèles)
# Série 6/7 (GeForce 6xxx, 7xxx) — pilote obsolète
sudo pacman -S nvidia-304xx

# Série 8/9/100/200/300 (GeForce 8xxx à GTX 700) — pilote legacy
sudo pacman -S nvidia-340xx

# Si aucun pilote ne fonctionne, utilisez VESA (mode de compatibilité)
# Déjà inclus, ajoutez "nomodeset" aux options du noyau au démarrage
```

### Pilotes d'imprimante

```bash
# Pilotes HP
sudo pacman -S hplip

# Pilotes Canon
sudo pacman -S cups-bjnp

# Pilotes Epson
sudo pacman -S epson-inkjet-printer-escpr  # si disponible

# Pilotes Brother
# Consultez le site de Brother pour les pilotes i686
```

---

## Mise à jour du système

Après l'installation, il est recommandé de mettre à jour le système pour bénéficier des dernières corrections de sécurité et des paquets les plus récents.

### Mise à jour complète

```bash
# Synchroniser les dépôts et mettre à jour tous les paquets
sudo pacman -Syu
```

### Mise à jour des clés de signature

Si vous rencontrez des erreurs de clés GPG :

```bash
# Initialiser et peupler le trousseau de clés
sudo pacman-key --init
sudo pacman-key --populate archlinux32

# Mettre à jour le trousseau
sudo pacman -Sy archlinux32-keyring
```

### Mise à jour des applications Flatpak

```bash
# Mettre à jour toutes les applications Flatpak
flatpak update
```

---

## Configuration du système

### Locale et langue

```bash
# Vérifier la locale actuelle
locale

# Modifier la locale (si nécessaire)
sudo nano /etc/locale.conf
# Contenu : LANG=fr_FR.UTF-8

# Régénérer les locales
sudo locale-gen
```

### Fuseau horaire

```bash
# Lister les fuseaux horaires disponibles
ls /usr/share/zoneinfo/Europe/

# Définir le fuseau horaire
sudo timedatectl set-timezone Europe/Paris

# Vérifier
timedatectl status
```

### Horloge matérielle

```bash
# Synchroniser l'horloge matérielle avec l'horloge système
sudo hwclock --systohc

# Vérifier
timedatectl
```

### Services système

```bash
# Lister les services actifs
systemctl list-units --type=service --state=running

# Activer un service au démarrage
sudo systemctl enable nom-du-service

# Désactiver un service
sudo systemctl disable nom-du-service

# Démarrer/arrêter un service immédiatement
sudo systemctl start nom-du-service
sudo systemctl stop nom-du-service
```

### Impression

```bash
# Vérifier que CUPS est en cours d'exécution
sudo systemctl status cups

# Lancer l'interface de configuration des imprimantes
system-config-printer
```

### Bluetooth (si supporté)

```bash
# Activer le service Bluetooth
sudo systemctl enable bluetooth
sudo systemctl start bluetooth

# Appairer un périphérique
bluetoothctl
# Dans bluetoothctl :
# power on
# scan on
# pair AA:BB:CC:DD:EE:FF
# trust AA:BB:CC:DD:EE:FF
# connect AA:BB:CC:DD:EE:FF
```

---

## Résolution des problèmes d'installation

Cette section couvre les problèmes les plus courants rencontrés lors de l'installation de nemOS et leurs solutions.

### Problème 1 : L'ordinateur ne démarre pas sur la clé USB

**Symptôme :** L'ordinateur démarre normalement sur le disque dur, ignorant la clé USB.

**Solutions :**
- Vérifiez que la clé USB est correctement flashée (essayez de la monter sur un autre ordinateur pour vérifier son contenu).
- Accédez au BIOS/UEFI et vérifiez que le démarrage USB est activé.
- Essayez un autre port USB (privilégiez les ports USB 2.0, les ports USB 3.0 peuvent poser problème sur les vieux PC).
- Essayez une autre méthode de création de la clé USB (Ventoy au lieu de dd).
- Sur certains anciens BIOS, il faut utiliser la touche de sélection de périphérique de démarrage (F12, F8, Esc) plutôt que de modifier l'ordre de démarrage.

### Problème 2 : Écran noir au démarrage de la session live

**Symptôme :** Après la sélection dans le menu Syslinux, l'écran devient noir et rien ne se passe.

**Solutions :**
- Redémarrez et choisissez l'option **« Mode sans échec (nomodeset) »** dans le menu Syslinux.
- Au menu Syslinux, sélectionnez la première option, appuyez sur `Tab` pour éditer la ligne de commande du noyau, et ajoutez `nomodeset` à la fin de la ligne. Appuyez sur `Entrée` pour démarrer.
- Si `nomodeset` résout le problème, le pilote vidéo de votre carte n'est pas compatible. Après l'installation, ajoutez `nomodeset` de manière permanente dans la configuration du bootloader.

### Problème 3 : Calamares ne se lance pas

**Symptôme :** Cliquant sur l'icône de l'installateur ne fait rien ou produit une erreur.

**Solutions :**
- Lancez Calamares depuis un terminal pour voir les messages d'erreur :
  ```bash
  sudo calamares -d
  ```
- Vérifiez que vous avez suffisamment de mémoire vive (minimum 512 Mio, 1 Gio recommandé).
- Vérifiez que l'espace disque est suffisant (minimum 8 Gio libres).
- Si Calamares se lance mais plante, consultez le journal : `cat /var/log/calamares.log`.

### Problème 4 : Erreur lors du partitionnement

**Symptôme :** Calamares affiche une erreur pendant le partitionnement (« Impossible de créer la partition », « Erreur d'écriture sur le disque »).

**Solutions :**
- Vérifiez que le disque n'est pas monté : `lsblk` et démontez-le si nécessaire avec `sudo umount`.
- Le disque est peut-être en lecture seule. Vérifiez le commutateur physique sur les cartes SD ou les anciens disques durs externes.
- Si le disque a été partitionné par Windows, il peut être verrouillé par le démarrage rapide (Fast Startup). Désactivez le démarrage rapide dans Windows avant d'installer nemOS.
- Pour les disques GPT, essayez de les convertir en MBR avec `sudo fdisk /dev/sdX` puis la commande `o` (créer une nouvelle table DOS).

### Problème 5 : L'installation se bloque à un certain pourcentage

**Symptôme :** La barre de progression de Calamares reste bloquée à un certain pourcentage.

**Solutions :**
- Patientez : certaines étapes (copie de fichiers, installation des paquets) peuvent prendre du temps sur les disques lents.
- Cliquez sur « Afficher le journal » pour voir ce qui se passe.
- Si l'installation est complètement bloquée depuis plus de 15 minutes, il y a probablement un problème. Redémarrez et réessayez.
- Réduisez la quantité de paquets installés en modifiant le profil de construction si vous construisez l'ISO vous-même.

### Problème 6 : Après l'installation, l'ordinateur ne démarre pas

**Symptôme :** Après le redémarrage post-installation, l'ordinateur affiche un écran noir, un message d'erreur ou démarre directement sur un autre système.

**Solutions :**
- Vérifiez que vous avez retiré la clé USB.
- Accédez au BIOS et vérifiez que le disque dur est en premier dans l'ordre de démarrage.
- Si le message « GRUB » ou « Syslinux » apparaît mais pas le menu de démarrage, le bootloader est installé mais mal configuré.
- Si vous avez un autre système d'exploitation, vous devrez peut-être réinstaller son bootloader (ex : `bootrec /fixmbr` sous Windows) et ajouter nemOS au menu de démarrage.
- Essayez de démarrer en mode de secours depuis la clé USB et vérifiez l'installation :

  ```bash
  sudo mount /dev/sda1 /mnt
  sudo arch-chroot /mnt
  # Vérifier la configuration du bootloader
  cat /boot/syslinux/syslinux.cfg
  ```

### Problème 7 : Pas de réseau après l'installation

**Symptôme :** Après le premier démarrage, aucune connexion réseau n'est disponible.

**Solutions :**
- Vérifiez que NetworkManager est actif : `sudo systemctl status NetworkManager`.
- Si NetworkManager n'est pas actif, activez-le : `sudo systemctl enable --now NetworkManager`.
- Pour le Wi-Fi, vérifiez que le pilote est chargé : `ip link show` et `lspci -nnk | grep -iA2 net`.
- Si la carte Wi-Fi nécessite un firmware manquant, installez-le : `sudo pacman -S linux-firmware`.
- Pour les connexions filaires, vérifiez le câble et les LEDs du port Ethernet.

### Problème 8 : Pas de son après l'installation

**Symptôme :** Aucun son ne sort des haut-parleurs ou du casque.

**Solutions :**
```bash
# Vérifier que PipeWire fonctionne
systemctl --user status pipewire pipewire-pulse wireplumber

# Redémarrer les services audio
systemctl --user restart pipewire pipewire-pulse wireplumber

# Vérifier les sorties audio disponibles
wpctl status

# Vérifier que le volume n'est pas à zéro
pavucontrol

# Vérifier que le pilote son est chargé
sudo dmesg | grep snd
lsmod | grep snd

# Si aucun pilote n'est chargé
sudo modprobe snd-hda-intel
```

### Problème 9 : Le clavier n'est pas en AZERTY après l'installation

**Symptôme :** Le clavier tape en QWERTY au lieu de AZERTY.

**Solutions :**
```bash
# Définir la disposition du clavier en AZERTY
sudo localectl set-x11-keymap fr pc105

# Ou via setxkbmap (temporaire, pour la session en cours)
setxkbmap fr

# Vérifier la configuration actuelle
localectl status
```

### Problème 10 : L'installation échoue avec « Pas assez d'espace disque »

**Symptôme :** Calamares affiche un message indiquant qu'il n'y a pas assez d'espace pour l'installation.

**Solutions :**
- La taille minimale requise est de 8 Gio. Si votre disque est plus petit, vous devrez construire une ISO personnalisée avec moins de paquets (voir le [guide de construction](BUILD.md)).
- Libérez de l'espace en supprimant des partitions inutiles avec GParted (accessible depuis la session live).
- Si vous avez un disque de 8 Gio, envisagez d'utiliser le swap sur fichier plutôt qu'une partition swap dédiée pour économiser de l'espace.

### Problème 11 : Erreur « Signature de paquet non valable »

**Symptôme :** Lors de la mise à jour après l'installation, pacman affiche des erreurs de signature de paquet.

**Solutions :**
```bash
# Réinitialiser le trousseau de clés
sudo rm -rf /etc/pacman.d/gnupg
sudo pacman-key --init
sudo pacman-key --populate archlinux32

# Mettre à jour le paquet de clés
sudo pacman -Sy archlinux32-keyring

# Réessayer la mise à jour
sudo pacman -Syu
```

### Problème 12 : Dual boot avec Windows — Windows ne démarre plus

**Symptôme :** Après l'installation de nemOS à côté de Windows, Windows ne apparaît pas dans le menu de démarrage.

**Solutions :**
- Ce problème peut survenir si le bootloader a été installé sur le MBR au lieu de la partition root.
- Pour restaurer Windows, démarrez depuis un support d'installation Windows et exécutez les commandes de réparation du bootloader.
- Pour ajouter Windows au menu Syslinux de nemOS, éditez `/boot/syslinux/syslinux.cfg` et ajoutez une entrée pour la partition Windows.
- Pour éviter ce problème, lors du partitionnement dans Calamares, installez le bootloader sur la partition root (`/dev/sda1`) et non sur le MBR (`/dev/sda`).

---

<div align="center">

  **Besoin d'aide supplémentaire ?**

  [Ouvrir une issue sur GitHub](https://github.com/nemesisastarte-gif/nemOS/issues) · [Consulter le README](../README.md) · [Guide de construction](BUILD.md)

</div>