<h1 align="center">wsl-clip-image</h1>

<p align="center">
  <em>Une capture, puis <code>Alt+V</code>. C'est tout.</em>
</p>

<p align="center">
  <img src="https://img.shields.io/github/stars/emmett001/wsl-clip-image?style=flat-square&color=111111&label=stars" alt="Stars">
  <img src="https://img.shields.io/badge/wsl2-Ubuntu-111111?style=flat-square" alt="WSL2 Ubuntu">
  <img src="https://img.shields.io/badge/works%20with-pi-111111?style=flat-square" alt="Works with pi">
  <img src="https://img.shields.io/badge/license-MIT-111111?style=flat-square" alt="MIT license">
</p>

<p align="center">
  <strong>Quatre étapes réduites à deux.</strong><br>
  <strong>Disparus : « envoyer à Transfert de fichiers » et « cliquez sur Copier ».</strong><br>
  <sub>Windows 11 · WSL2 Ubuntu · pi · 82–125 ms mesurés</sub>
</p>

<p align="center">
  <sub><a href="../README.md">English</a> &middot; <a href="README.zh-CN.md">简体中文</a> &middot; <a href="README.ja.md">日本語</a> &middot; <a href="README.ko.md">한국어</a> &middot; <a href="README.ru.md">Русский</a></sub>
</p>

---

## Les deux étapes en trop

Vous voulez montrer une boîte d'erreur à l'agent qui tourne dans votre terminal.

`Alt+A`, vous encadrez, `Enter`. L'image est dans le presse-papiers.

De retour au terminal, `Ctrl+V`. Rien ne se passe.

Alors vous ouvrez WeChat, vous trouvez « Transfert de fichiers », vous envoyez l'image, vous attendez qu'elle apparaisse, clic droit, « Copier ».

De retour au terminal, `Ctrl+V` encore. Cette fois quelque chose arrive — une ligne du genre `F:\xwechat_files\wxid_xxx\temp\RWTemp\...png`.

Ça marche, et votre agent sait lire ce chemin. Mais pour coller une seule capture, vous avez ouvert une messagerie, envoyé un message et cliqué une fois sur « Copier ».

## Après installation

```
Alt+A capture  →  Alt+V  →  /tmp/pi-clipboard-3f2a91c8-....png
```

Appuyez sur `Alt+V` : le programme lit lui-même le presse-papiers, écrit un fichier et place le chemin dans la zone de saisie.

`Alt+A` de WeChat fonctionne. `Win+Shift+S` de Windows aussi.

## Installation

```bash
sudo apt install -y wl-clipboard imagemagick
git clone https://github.com/emmett001/wsl-clip-image.git ~/.agents/skills/wsl-clip-image
```

Ensuite : `Alt+A` → `Enter` → `Alt+V`. pi charge le skill à son prochain démarrage.

Sans pi, une seule commande :

```console
$ git clone https://github.com/emmett001/wsl-clip-image.git
$ wsl-clip-image/scripts/grab.sh
/tmp/wslclip-20261106-174535-2946895.png
```

`grab.sh` affiche un chemin Linux. `cat`, `identify` et `cp` l'acceptent tel quel.

## Environnements testés

| | |
|-|-|
| Testé | Windows 11 · WSL2 Ubuntu · Windows Terminal · pi 1.5.0 |
| Testé | `grab.sh` appelé depuis n'importe quel script, même configuration |
| Non testé | Autres agents, autres terminaux, autres distributions, WSL1, Linux natif, macOS |

`Alt+V` est une combinaison propre à pi. Un autre agent apporte sa propre touche, et sa propre idée des chemins d'image.
`grab.sh` s'appuie sur bash et sur les outils système, il devrait donc passer plus facilement ailleurs. Aucun test pour l'instant.

## Chiffres

Une capture 1920x1020, même machine :

| Chemin | Durée |
|-|-|
| `wl-paste` (dans pi) | 82–125 ms |
| `wl-paste` + ImageMagick (`grab.sh`) | 210 ms |
| Repli PowerShell | 660–1709 ms |

`wl-clipboard` fait la frontière : 5 à 17 fois plus rapide.

## Si le collage échoue

```console
$ scripts/doctor.sh
== 1. WSL interop ==          ok  binfmt WSLInterop enregistré
== 2. powershell.exe ==       ok  exécutable
== 3. Outils presse-papiers == ok  wl-paste présent, chemin rapide : image/bmp
== 4. Presse-papiers Windows == ok  image récupérée, 82 ms
Verdict : le chemin fonctionne
```

| Symptôme | Correctif |
|-|-|
| `Exec format error`, ou `xxx.exe: 1: MZ...: not found` | `scripts/doctor.sh --fix` |
| « Aucune image dans le presse-papiers » | Capture inachevée, ou une autre application a pris le raccourci |
| `Alt+V` met 1 à 2 s | `sudo apt install -y wl-clipboard` |
| Une image « expire » | Le processus propriétaire du presse-papiers s'est arrêté. Refaites la capture |

Deux points faciles à confondre :

| Idée courante | Ce qui se passe vraiment |
|-|-|
| La capture est stockée dans le presse-papiers sous forme de fichier | Elle y est stockée sous forme de bitmap. Un chemin de fichier n'apparaît qu'après « envoyer, puis Copier » |
| Il faut d'abord l'envoyer à Transfert de fichiers | Dès que vous appuyez sur `Enter`, le presse-papiers la contient déjà |

## Hors périmètre

Historique et recherche du presse-papiers, copie de texte, et envoi d'images de WSL vers Windows.

## Licence

[MIT](../LICENSE)
