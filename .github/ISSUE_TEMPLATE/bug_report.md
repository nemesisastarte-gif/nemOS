---
name: Rapport de bogue
about: Signaler un problème ou un bogue dans nemOS
title: "[BUG] "
labels: bug
assignees: ''

---

## Description du problème

Décrivez brièvement le problème que vous rencontrez. Soyez aussi précis que possible.

> Exemple : « Le Wi-Fi ne se connecte pas automatiquement au démarrage sur mon ASUS Eee PC 900. »

---

## Étapes pour reproduire

Listez les étapes nécessaires pour reproduire le problème :

1. ...
2. ...
3. ...

---

## Comportement attendu

Décrivez ce qui *devrait* se produire normalement.

> Exemple : « La connexion Wi-Fi devrait s'établir automatiquement si un réseau connu est disponible. »

---

## Comportement observé

Décrivez ce qui se passe *réellement*.

> Exemple : « Aucun réseau Wi-Fi n'est détecté. L'icône NetworkManager affiche « Aucun périphérique réseau ». »

---

## Configuration matérielle

| Composant | Détail |
|-----------|--------|
| Machine / Modèle | ex. : Lenovo ThinkPad X61 |
| Processeur | ex. : Intel Core 2 Duo T7300 |
| Mémoire vive | ex. : 2 Go DDR2 |
| Carte graphique | ex. : Intel GMA X3100 |
| Carte réseau | ex. : Intel PRO/Wireless 4965AGN |
| Stockage | ex. : SSD 128 Go |
| Version de nemOS | ex. : v1.0.0 |

---

## Journal des erreurs

Joignez les journaux pertinents. Vous pouvez les obtenir avec les commandes suivantes :

```bash
# Journal système récent
journalctl -b -p err

# Journal de démarrage
journalctl -b

# Journal de NetworkManager
journalctl -u NetworkManager

# Log du noyau
dmesg | tail -50
```

Collez les sorties pertinentes ci-dessous :

```
Collez les journaux ici entre les triples backticks.
```

---

## Captures d'écran

Si possible, ajoutez des captures d'écran illustrant le problème.

---

## Informations supplémentaires

Tout autre détail qui pourrait aider à résoudre le problème (solutions essayées,
contexte particulier, etc.) :

- [ ] Le problème se produit également sur le système live (ISO bootée sans installation)
- [ ] Le problème est reproductible de manière constante
- [ ] J'ai cherché dans les issues existantes avant d'ouvrir celle-ci