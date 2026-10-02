<img src="https://github.com/MathysM-Yt.png" width="120px" align="left">

### `Logiciels Utiles by Mathys M`

[![Downloads](https://img.shields.io/github/downloads/MathysM-Yt/Logiciels-Utiles/total.svg)](https://github.com/MathysM-Yt/Logiciels-Utiles/releases)

<br clear="left">

<div flex="true">
  <a href="https://www.karde.me/mathysm">
    Mes réseaux
  </a>
  •
  <a href="https://github.com/MathysM-Yt/Logiciels-Utiles/releases">
    Télécharger
  </a>
  •
  <a href="https://ko-fi.com/mathysm">
    Soutenir le projet
  </a>
</div>

<br>

`Logiciels Utiles by Mathys M` regroupe une sélection de logiciels que je recommande pour Windows

Un script par logiciel avec vidéo de présentation, raccourci vers le site officiel/GitHub, installation et mise à jour automatisées

## Présentation

Clique pour voir la vidéo :)

[![Voir la vidéo de présentation](https://img.youtube.com/vi/BUla3mZsCs4/maxresdefault.jpg)](https://youtu.be/BUla3mZsCs4)

## Preview

![Contenu du dossier](./Ressources/Assets/Screen%20dossier.png)

## Démarrer

- **`Logiciels Utiles.bat`** : lanceur principal. Il liste les catégories, puis les logiciels, et exécute le script choisi.
- **`Installation par catégorie.bat`** : navigation par catégorie avec compteurs, recherche par nom (`S`), puis installation d'un logiciel, d'une sélection (`1,3,5`) ou de toute une catégorie (`a`). Gère `winget`, `choco` (Chocolatey installé au besoin), les URLs (ouverture de la page de téléchargement) et signale les scripts à installer manuellement. Chaque action est journalisée dans `Ressources/install.log`.

## Contenu

Les logiciels sont classés par catégorie. Chaque script `.bat` propose un menu : présentation (vidéo), site officiel/GitHub, installation automatique via `winget`, et mise à jour via `winget` quand elle est disponible.

### Apparence
Mica For Everyone • Seelen UI • Spicetify • Wallpaper Engine • Windhawk • Lively Wallpaper • TranslucentTB

### Audio
Dolby • Nvidia Broadcast • EarTrumpet • Audacity • foobar2000
- **Mixage - Routage** : VoiceMeeter • Wave Link 3

### Diagnostic
CapFrameX • HWiNFO • MemTest86 • UserDiag • CrystalDiskInfo

### Gaming
DLSS Swapper • DS4 Windows • Lossless Scaling • Playnite • Prism Launcher • Heroic Games Launcher • Project GLD
- **Carte graphique** : DDU
  - **AMD** : Radeon Software Slimmer
  - **Nvidia** : NVCleanstall • Nvidia Profile Inspector
- **Cloud Gaming** : Boosteroid • GeForce Now

### Gestion des logiciels
BCUninstaller • Revo Uninstaller • UniGetUI

### Navigateur
Sine • Zen Browser • Firefox • Brave
- **Extensions** : Enhancer for YouTube • Streaming Enhanced

### Optimisation
Winhance • Czkawka

### Productivité
App Group • File Pilot • Files App • Flow Launcher • PowerToys • Twinkle Tray • Window Centering • ShareX • AutoHotkey • Obsidian • Lightshot

### Stream
OBS • OBS Multi RTMP

### Développement
Visual Studio Code • Git • Python • Node.js

### Bureautique
LibreOffice • OnlyOffice • Joplin • Thunderbird

### Sécurité
Bitwarden • KeePassXC • VeraCrypt • Cryptomator

### Graphisme
GIMP • Krita • Inkscape • Blender • IrfanView

### Multimédia
VLC • HandBrake • MPC-HC

### Utilitaires
7-Zip • NanaZip • Rufus • Ventoy • LocalSend • Syncthing • FileZilla • Everything

## Ajouter un logiciel

Crée un nouveau fichier `.bat` en copiant un script existant de la même catégorie, puis modifie uniquement le bloc **Config du script** en haut du fichier :

```bat
set "Logiciel=Nom du logiciel"
set "Presentation=https://youtu.be/..."        :: vidéo de présentation
set "Github=https://github.com/..."            :: site officiel / GitHub
set "Install=winget.exe install --id <identifiant.winget> --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements --force"
set "Update=winget.exe upgrade --id <identifiant.winget> --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements"
```

L'entrée de menu **4. Mettre à jour** utilise la variable `Update`.

L'identifiant `winget` se trouve avec `winget search <nom>`.

### Bibliothèque partagée `_core.bat`

Les scripts standards n'embarquent plus les menus, l'élévation ni le compte à rebours : ils appellent la bibliothèque partagée `Ressources/_core.bat`.

```bat
set "_CORE=%~dp0..\..\Ressources\_core.bat"   :: chemin absolu (%~dp0)
call "%_CORE%" :AdminCheck "%~f0"              :: "%~f0" = chemin du script appelant
...
call "%_CORE%" :LogoHeader
call "%_CORE%" :DoInstall
call "%_CORE%" :DoUpdate
```

`_core.bat` fournit : `:AdminCheck` (élévation), `:LogoHeader`, `:DoInstall`, `:DoUpdate`, `:Countdown` et `:Log`.

> ⚠️ `cmd.exe` n'accepte pas `call fichier.bat :Label` comme un saut direct : il exécute le fichier **depuis le début** et passe `:Label` dans `%1`. `_core.bat` commence donc par un *dispatcher* (`if not "%~1"=="" goto %~1`) qui redirige vers le bon label. L'appel `:AdminCheck` doit **toujours** transmettre `"%~f0"`, sinon l'élévation relancerait `_core.bat` au lieu du script.

> ⚠️ **Important :** les fichiers `.bat` doivent être enregistrés en **CRLF** (fins de ligne Windows), sinon `cmd.exe` ne trouve pas les labels (`goto`) et le script ne fonctionne pas. Le fichier `.gitattributes` force déjà `*.bat` en CRLF.

## Contrôle qualité (QC)

Avant chaque release, exécutez le script de vérification pour détecter les erreurs :

```bash
python3 Ressources/qc-check.py
```

Vérifications effectuées :
1. **Extensions CRLF** — tous les `.bat` doivent être en CRLF
2. **Cohérence goto/labels** — chaque `goto :Label` a un `:Label` correspondant
3. **Cohérence CHOICE/ERRORLEVEL** — chaque chiffre du CHOICE a son `IF ERRORLEVEL N GOTO`
4. **Format winget** — `Install=` contient `install`, `Update=` contient `upgrade` sans `--force`
5. **Scripts non-winget** — détection des URLs, choco, scripts personnalisés
6. **Variable `Logiciel=`** obligatoire
7. **Labels de menu standard** — `:Menu`, `:Présentation`, `:Github`
8. **Appel `:AdminCheck`** — transmet le chemin du script (`"%~f0"`) pour l'élévation

Pour corriger automatiquement les fichiers en LF :
```bash
python3 Ressources/qc-check.py --fix-crlf
```
