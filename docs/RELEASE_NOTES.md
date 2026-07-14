# nemOS v1.0.0 — Notes de version

**Date de publication :** 15 janvier 2025  
**Codebase :** Arch Linux 32 (i686)  
**Desktop :** XFCE 4 avec personnalisation nemOS  
**Noyau :** Linux LTS optimisé i686

---

## Présentation

Nous sommes fiers d'annoncer la toute première version stable de **nemOS**, une distribution GNU/Linux
légère et élégante conçue spécifiquement pour l'architecture 32 bits (i686). Dans un monde où le
support matériel 32 bits est progressivement abandonné par les grandes distributions, nemOS apporte
une réponse concrète aux utilisateurs possédant du matériel vintage, des netbooks, ou des machines
à faibles ressources.

nemOS repose sur la solidité d'Arch Linux, combinée à un environnement de bureau XFCE soigneusement
thématisé et configuré pour offrir une expérience moderne et réactive, même sur du matériel datant
des années 2000-2010. Le gestionnaire de paquets `pacman` garantit un accès rapide et efficace aux
derniers logiciels maintenus par le projet Arch Linux 32.

Cette version 1.0.0 est le fruit de mois de développement, de tests sur du matériel réel et dans
des machines virtuelles QEMU. Elle représente notre base de travail pour les futures versions.

---

## Nouvelles fonctionnalités

### Système de base

- **Arch Linux 32 (i686) pur** — L'ensemble du système est compilé nativement pour l'architecture
  32 bits, garantissant une compatibilité maximale avec les processeurs i686 et ultérieurs
  (Pentium Pro, Celeron, Pentium M, Atom, etc.).
- **Noyau Linux LTS** — Un noyau à long terme assurant stabilité et support matériel étendu.
  Les pilotes essentiels pour le Wi-Fi, le son, les cartes graphiques Intel/AMD/NVIDIA
  héritées sont inclus.
- **Pacman avec miroirs Arch Linux 32** — Le gestionnaire de paquets est préconfiguré avec
  les miroirs du projet Arch Linux 32 pour des téléchargements rapides et fiables.
- **Démarrage Syslinux** — Le chargeur d'amorçage Syslinux assure une compatibilité
  maximale avec les vieux BIOS sans support UEFI.

### Environnement de bureau

- **XFCE 4** — L'environnement de bureau léger par excellence, configuré avec un
  équilibre entre modernité et performances. Panneau personnalisé, gestionnaire de
  fenêtres ajusté, et raccourcis clavier optimisés.
- **Thème GTK nemOS-Dark** — Un thème sombre élégant créé spécialement pour nemOS,
  disponible en GTK 2 et GTK 3. Les applications s'intègrent harmonieusement
  dans l'ensemble visuel.
- **Fonds d'écran originaux** — Quatre fonds d'écran exclusifs créés pour nemOS :
  - *nemos-default* : le fond par défaut avec le logo nemOS
  - *nemos-dark* : une variante sombre pour le thème dark
  - *nemos-ocean* : un fond d'apaisement avec des tons bleus
  - *nemos-sunset* : un fond chaleureux aux teintes de coucher de soleil
- **Logo personnalisé** — Le logo nemOS est intégré partout dans le système :
  écran de connexion, menu Démarrer, écran de démarrage, et favicon du navigateur.

### Outils nemOS

- **nemOS Store** — Une application de catalogue de paquets en Python/GTK qui permet
  de parcourir et d'installer facilement les logiciels les plus populaires. Le catalogue
  est stocké dans un fichier JSON local et peut être mis à jour.
- **Script de premier démarrage** — Au premier lancement, nemOS vous accueille avec
  un assistant qui configure automatiquement la locale, le fuseau horaire, le clavier,
  et crée l'utilisateur par défaut. Cette expérience « live » est conçue pour être
  aussi fluide que possible.
- **Configuration des services** — Un script `services.sh` gère les services systemd
  activés par défaut (réseau, Bluetooth, son, impression, etc.) avec des options
  configurables.
- **Nettoyage automatique** — Le script de nettoyage supprime les paquets de cache,
  les journaux temporaires et les fichiers inutiles après la construction de l'ISO,
  réduisant la taille finale de l'image.

### Construction et développement

- **Script de construction automatisé** — `build.sh` orchestre l'ensemble du processus
  de création de l'ISO, depuis l'installation des paquets jusqu'à la génération de
  l'image finale avec `mkarchiso`.
- **Profil archiso complet** — Le profil `nem/` contient toute la configuration
  nécessaire pour une construction reproductible : profiledef.sh, pacman.conf,
  configuration Syslinux, et arborescence airootfs.
- **CI/CD GitHub Actions** — Des workflows automatisés vérifient la cohérence du
  projet à chaque commit : validation structurelle, analyse ShellCheck, vérification
  JSON, et détection de secrets.
- **Documentation complète** — Les guides de construction (`docs/BUILD.md`) et
  d'installation (`docs/INSTALL.md`) accompagnent le projet pour faciliter
  la contribution et l'utilisation.

---

## Configuration matérielle minimale

| Composant | Minimum | Recommandé |
|-----------|---------|------------|
| Processeur | i686 (Pentium Pro, 1995+) | Pentium M ou supérieur |
| Mémoire vive | 512 Mo | 1 Go ou plus |
| Stockage | 4 Go (installation) | 8 Go ou plus |
| Carte graphique | VGA compatible | Intel GMA / Radeon |
| Réseau | Ethernet | Wi-Fi 802.11b/g |

**Remarque :** nemOS est conçu pour fonctionner sur du matériel datant des années 2000.
Les machines suivantes ont été testées avec succès :

- Lenovo ThinkPad X60 / X61
- ASUS Eee PC 701 / 900
- Dell Latitude D630
- HP Compaq nx6325
- Toshiba Satellite L40

---

## Installation

### Depuis l'ISO live

1. Téléchargez l'ISO depuis la section *Releases* de ce dépôt.
2. Gravez l'ISO sur un CD/DVD ou créez une clé USB bootable :
   ```bash
   dd if=nemOS-1.0.0-YYYYMMDD-i686.iso of=/dev/sdX bs=4M status=progress
   ```
3. Démarrez votre ordinateur sur le média d'installation.
4. Le système live se lance automatiquement — profitez-en pour tester
   que tout fonctionne (son, Wi-Fi, graphiques).
5. Lancez l'installateur depuis le bureau ou le terminal.

### Dans une machine virtuelle (QEMU)

```bash
qemu-system-i386 -m 1024 -smp 2 -cdrom nemOS-1.0.0-YYYYMMDD-i686.iso -boot d
```

---

## Paquets inclus

nemOS v1.0.0 inclut plus de 200 paquets essentiels, parmi lesquels :

**Base système :** base, base-devel, linux-lts, systemd, pacman, sudo, tzdata, locales

**Bureau :** xfce4, xfce4-goodies, xfwm4, xfce4-panel, xfce4-terminal, thunar, ristretto

**Multimédia :** vlc, audacious, ffmpeg, pulseaudio, alsa-utils, pavucontrol

**Internet :** firefox-esr, thunderbird, networkmanager, nm-connection-editor, wpa_supplicant

**Bureautique :** libreoffice-still, evince, xpdf

**Utilitaires :** htop, neofetch, vim, nano, git, wget, curl, file-roller, catfish

**Graphisme :** gimp, inkscape, screenshots

*Consultez `packages/packages.i686` pour la liste complète.*

---

## Problèmes connus

1. **Wi-Fi Realtek RTL8187** — Certains adaptateurs USB Wi-Fi basés sur ce chipset
   peuvent nécessiter l'installation manuelle du paquet `rtl8187-firmware` depuis
   l'AUR d'Arch Linux 32.
2. **Cartes NVIDIA anciennes (série GeForceFX)** — Le pilote `nouveau` peut
   présenter des artefacts graphiques. L'utilisation du pilote propriétaire
   `nvidia-340xx` est recommandée si disponible pour votre carte.
3. **Suspend/Reprise** — La reprise depuis la mise en veille peut échouer sur
   certains modèles de portables anciens. Ce problème est lié au noyau et
   non à la configuration de nemOS.
4. **Nécessite un BIOS traditionnel** — nemOS 1.0.0 ne supporte pas le démarrage
   UEFI. Le support UEFI 32 bits (ia32) est prévu pour la v1.1.
5. **Taille de l'ISO** — L'ISO pèse environ 1,2 Go en raison de l'inclusion
   des paquets de bureau et multimédia. Une version « core » plus légère
   est envisagée.
6. **Thunderbird** — Peut être lent au premier lancement sur les machines
   avec moins de 768 Mo de RAM.

---

## Développement

Contribuer à nemOS est simple et ouvert à tous :

1. **Fork** ce dépôt et créez une branche pour votre fonctionnalité.
2. **Modifiez** les fichiers nécessaires (paquets, configuration, scripts).
3. **Testez** vos modifications avec `./build.sh` dans un environnement i686.
4. **Soumettez** une pull request avec une description claire de vos changements.

Le guide complet de développement se trouve dans `docs/BUILD.md`.

### Structure du projet

```
nemOS/
├── .github/           # Templates d'issues et workflows CI/CD
├── build.sh           # Script de construction principal
├── services.sh        # Configuration des services systemd
├── packages/          # Listes de paquets par architecture
├── nem/               # Profil archiso (airootfs, syslinux, pacman)
├── nemOS-assets/      # Logo, fonds d'écran, ressources graphiques
├── nemOS-store/       # Application de catalogue de paquets
├── scripts/           # Scripts de premier démarrage et construction
├── docs/              # Documentation
└── out/               # Répertoire de sortie (généré par build.sh)
```

---

## Remerciements

- **Arch Linux** et **Arch Linux 32** pour la base exceptionnelle et les paquets maintenus.
- **XFCE** pour l'environnement de bureau léger et personnalisable.
- **L'équipe archiso** pour les outils de création d'images ISO.
- **La communauté open source** pour les innombrables logiciels libres qui composent nemOS.
- Tous les **bêta-testeurs** qui ont testé nemOS sur du matériel réel et rapporté
  des retours précieux.

---

## Licence

nemOS est distribué sous licence GNU General Public License v3.0.  
Consultez le fichier `LICENSE` pour plus de détails.

---

**Téléchargement :** [nemOS-1.0.0](https://github.com/nemesisastarte-gif/nemOS/releases/tag/v1.0.0)

**Site web :** https://github.com/nemesisastarte-gif/nemOS

**Problèmes :** [Ouvrir une issue](https://github.com/nemesisastarte-gif/nemOS/issues)

---

*La nostalgie n'est pas ce qu'elle était. NemOS, c'est la nostalgie de demain.*