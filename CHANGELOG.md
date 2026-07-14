# Journal des modifications de nemOS

Toutes les modifications notables apportées à nemOS seront documentées dans ce fichier.

Le format est basé sur [Keep a Changelog](https://keepachangelog.com/fr/1.1.0/),
et ce projet adhère au [Versionnement Sémantique](https://semver.org/lang/fr/).

---

## [1.0.0] - 2025-07-15

### Ajouté

#### Système de base
- Première version publique de nemOS, distribution Linux 32-bit ultra-légère.
- Base sur Arch Linux 32 avec noyau Linux optimisé pour l'architecture i686.
- Support des processeurs Intel Pentium III et supérieurs, AMD Athlon XP et supérieurs.
- Support PAE pour l'adressage de plus de 4 Gio de mémoire vive.
- Gestionnaire de système systemd avec configuration allégée.
- Pages de manuel en français (`man-pages-fr`) installées par défaut.

#### Interface graphique
- Interface macOS-like complète avec Openbox + Plank + Tint2.
- Thème GTK3 « nemOS-Dark » inspiré de macOS Mojave Dark.
  - Couleurs sombres cohérentes pour tous les widgets GTK.
  - Bordures arrondies sur les boutons, les entrées et les barres de défilement.
  - Ombres portées subtiles sur les fenêtres et les menus.
  - Dégradés personnalisés sur les barres de titre.
- Thème GTK2 « nemOS-Dark » pour la compatibilité avec les applications anciennes.
- Moteur de rendu Murrine pour les thèmes GTK2.
- Support Kvantum pour les applications Qt.
- Compositeur xcompmgr pour la transparence et les ombres portées.
- Lanceur d'applications Rofi avec thème personnalisé intégré à l'interface sombre.
- Barre des tâches Tint2 avec horloge, contrôle du volume, état du réseau et lanceur.

#### Dock Plank
- Dock d'application style macOS avec animations de zoom au survol.
- Icônes d'application par défaut préconfigurées (Firefox ESR, PCManFM, Terminal, etc.).
- Indicateurs visuels pour les applications en cours d'exécution.
- Support du glisser-déposer pour épingler des applications.

#### Bureau et gestionnaire de fichiers
- Gestionnaire de fichiers PCManFM configuré avec le thème sombre.
- Gestionnaire de fichiers Thunar comme alternative avec plugins (archive, volume, miniatures).
- Support GVFS pour les périphériques amovibles, les partages réseau (SMB) et les appareils MTP.
- File-Roller et Xarchiver pour la gestion des archives (tar, zip, rar, 7z).
- Générateur de miniatures Tumbler pour les aperçus de fichiers.

#### Audio
- Serveur audio/vidéo PipeWire par défaut avec compatibilité PulseAudio.
- Wireplumber comme gestionnaire de session PipeWire.
- Support PipeWire-ALSA pour les applications utilisant ALSA directement.
- Support PipeWire-Pulse pour les applications utilisant PulseAudio.
- Contrôle du volume graphique avec pavucontrol.
- Icône de volume Volumeicon dans la barre Tint2.
- Outils ALSA pour le diagnostic et la configuration avancée.

#### Pilotes vidéo
- Pilote VESA (`xf86-video-vesa`) pour la compatibilité maximale.
- Pilote Intel (`xf86-video-intel`) pour les cartes graphiques Intel intégrées.
- Pilote ATI (`xf86-video-ati`) pour les cartes AMD/ATI.
- Pilote Nouveau (`xf86-video-nouveau`) pour les cartes NVIDIA.
- Pilote framebuffer (`xf86-video-fbdev`) pour les consoles virtuelles.
- Serveur X.org avec support RandR pour la gestion des écrans.
- Mesa pour l'accélération 3D open source.

#### Réseau
- NetworkManager comme gestionnaire réseau unifié.
- Éditeur de connexions graphique (nm-connection-editor).
- Support Wi-Fi avec WPA Supplicant et iwd.
- Outils réseau en ligne de commande (net-tools, wireless_tools).
- OpenSSH pour les connexions distantes sécurisées.
- Curl, wget et rsync pour les transferts de données.

#### Navigateur web
- Firefox ESR (Extended Support Release) préinstallé et configuré.
- Support des codecs multimédia web via GStreamer.

#### Suite bureautique
- LibreOffice Fresh avec module linguistique français complet.
- Traitement de texte Writer, tableur Calc, présentation Impress.
- Éditeur de dessin Draw, base de données Base, éditeur de formules Math.

#### Multimédia
- Lecteur multimédia VLC avec support de tous les formats courants.
- Lecteur léger mpv pour la lecture en ligne de commande.
- Infrastructure GStreamer complète (plugins good, bad, ugly, libav).
- Support FFmpeg pour l'encodage et le décodage vidéo.
- Génération de miniatures vidéo avec ffmpegthumbnailer.

#### Outils système
- Éditeur de partitions graphique GParted.
- Utilitaire de gestion des disques GNOME Disks.
- Outil de récupération de données TestDisk.
- Support des systèmes de fichiers : ext4, btrfs, f2fs, exFAT, NTFS (lecture/écriture), FAT32.
- Outils de chiffrement LUKS (cryptsetup).
- Moniteur de processus interactif htop.
- Outils d'information matériel : lshw, inxi, hwinfo, usbutils, pciutils.

#### Impression
- Système d'impression CUPS.
- CUPS-PDF pour l'impression vers fichier PDF.
- Interface de configuration des imprimantes (system-config-printer).

#### Gestion des paquets
- Gestionnaire de paquets pacman avec configuration optimisée.
- Pamac avec support AUR pour l'installation graphique de paquets.
- Support Flatpak pour les applications conteneurisées.

#### Sécurité
- Sudo pour l'élévation de privilèges.
- Polkit pour le contrôle d'accès fin aux opérations système.
- GNOME Keyring pour le stockage sécurisé des mots de passe.
- Gestionnaire de clés Seahorse.

#### Applications de développement
- Éditeur de texte Geany avec coloration syntaxique.
- Éditeurs en console Vim et Nano.
- Émulateur de terminal Xfce4-Terminal avec onglets et transparence.
- Coloration syntaxique améliorée pour Nano (nano-syntax-highlighting).

#### Capture d'écran
- Outil de capture d'écran en ligne de commande Scrot.
- Outil de capture d'écran graphique Spectacle.

#### Visionneuses d'images
- Ristretto — visionneuse d'images légère du projet Xfce.
- Gpicview — visionneuse d'images minimale et très rapide.

#### Polices de caractères
- DejaVu Sans, Serif et Mono — polices Unicode complètes.
- Liberation Sans, Serif et Mono — polices métriquement équivalentes aux polices Microsoft.
- Bitstream Vera — polices bitmap optimisées pour les basses résolutions.
- Noto Sans — police Google avec large couverture Unicode.
- Configuration fontconfig optimisée.

#### Installateur
- Installateur graphique Calamares avec interface traduite en français.
- Support du partitionnement automatique et manuel.
- Support du chiffrement LUKS.
- Dépendances Python (PyQt5, PyYAML, Jinja2).

#### Scripts système
- Script de premier démarrage `nemos-firstboot.sh` :
  - Configuration assistée du nom d'hôte.
  - Configuration du réseau Wi-Fi.
  - Configuration de la locale française (fr_FR.UTF-8).
  - Vérification et génération du fstab.
  - Détection automatique des SSD et activation du TRIM.
  - Création du compte utilisateur avec groupes et sudo.
  - Activation des services système essentiels.
  - Application automatique du thème visuel.
  - Copie des fonds d'écran.
  - Proposition d'installation de Flatpak et Flathub.
- Script de construction `nemos-chroot-build.sh` pour les personnalisations pendant le build.
- Script de nettoyage `nemos-cleanup.sh` pour la maintenance du système.
- Script de gestion des services `services.sh` pour la session live et le build.

#### nemOS Store
- Magasin d'applications graphique développé en Python avec PyQt5.
- Catalogue d'applications organisé par catégories (JSON).
- Recherche instantanée par nom ou mot-clé.
- Installation en un clic via pacman.
- Entrée .desktop pour l'intégration au menu d'applications.
- Icône SVG personnalisée.

#### Ressources graphiques
- Logo nemOS au format SVG (standard et coins arrondis).
- Cinq fonds d'écran originaux :
  - `nemos-default.png` — fond d'écran par défaut avec dégradé sombre.
  - `nemos-dark.png` — variante sombre profonde.
  - `nemos-sunset.png` — dégradé aux tons chauds (coucher de soleil).
  - `nemos-ocean.png` — dégradé bleu océanique.
  - `nemos-minimal.png` — fond d'écran minimaliste et épuré.
- Script Python de génération des fonds d'écran.

#### Documentation
- README.md complet avec présentation, fonctionnalités, configuration requise et dépannage.
- Guide d'installation détaillé (docs/INSTALL.md) avec trois méthodes de création de clé USB.
- Guide de construction détaillé (docs/BUILD.md) pour la construction de l'ISO depuis les sources.
- Journal des modifications (CHANGELOG.md).

#### Boot et système de fichiers live
- Bootloader Syslinux avec support BIOS Legacy (MBR et El Torito).
- Compression SquashFS avec algorithme zstd niveau 22 pour une taille d'ISO minimale.
- Système de fichiers live avec persistance optionnelle.

### Configuration

#### Fichiers de configuration
- `/etc/os-release` — identification du système (nom, version, URL du projet).
- `/etc/lsb-release` — compatibilité LSB.
- `pacman.conf` — configuration pacman avec dépôts Arch Linux 32.
- `mirrorlist` — liste de miroirs Arch Linux 32.
- `profiledef.sh` — profil de construction archiso complet.

#### Outils de configuration
- Lxappearance — sélection de thème GTK, d'icônes et de polices.
- Obconf — configuration d'Openbox (thème de fenêtres, raccourcis, marges).
- qt5ct — configuration de l'apparence des applications Qt5.
- Zenity et Yad — boîtes de dialogue graphiques pour les scripts.

---

## [Non publié]

### En cours de développement

#### Planifié pour la version 1.1.0
- Support UEFI avec GRUB ou systemd-boot.
- Thème clair « nemOS-Light » en complément du thème sombre.
- Icônes personnalisées « nemOS-Icons » (remplacement des icônes Adwaita).
- Papiers peints supplémentaires générés par la communauté.
- Optimisation de la consommation mémoire (cible : 150 Mio au repos).
- Script de nettoyage automatique du cache pacman (`nemos-cleanup`).

#### Planifié pour la version 1.2.0
- Support des langues supplémentaires (anglais, espagnol, allemand, etc.).
- Calamares traduit dans les langues supportées.
- Calamares avec page de sélection de logiciels optionnels.
- Périphériques de pointage : configuration avancée du pavé tactile.
- Gestion de l'énergie : outils d'économie de batterie pour les portables.
- Notifications de bureau avec dunst ou xfce4-notifyd.

#### Planifié pour la version 2.0.0
- Migration vers LXQt comme environnement de bureau complet.
- Compositing avec picom (remplacement de xcompmgr).
- Intégration Wayland (expérimental) via cage ou sway.
- Outil de configuration graphique centralisé (nemOS Settings).
- Système de mise à jour automatique en arrière-plan.
- Support de l'architecture x86_64 (en plus de i686).

---

[1.0.0]: https://github.com/nemesisastarte-gif/nemOS/releases/tag/v1.0.0