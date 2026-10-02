# Logiciels Utiles — Dépôt GitHub

## Où vit le projet

- **Local** : `C:\Users\DYNOX2.0\Documents\worspace\logiciel utile\Logiciels-Utiles-1.1.0`
  (racine du dépôt : le dossier contient `README.md`, `LICENSE.md`, `.gitattributes`, `Ressources/` et le dossier des scripts `Logiciels Utiles/`)
- **GitHub** : <https://github.com/dannyembo725-max/Logiciels-Utiles> (privé, branche `main`)
- **Commit initial** : `7e2192d0b01272a1bb4e319b15f61f4dc2883d82`

## Ce que contient le dépôt

`Logiciels Utiles by Mathys M` — une sélection de logiciels recommandés pour Windows, un script `.bat`
par logiciel. Chaque script propose un menu : présentation (vidéo YouTube), site officiel/GitHub,
installation automatique (`winget`, parfois `choco` ou une URL de téléchargement) et mise à jour.

- `Logiciels Utiles.bat` — lanceur principal (navigation par dossiers, recherche par nom)
- `Installation par catégorie.bat` — installeur par catégorie, avec journalisation dans `Ressources/install.log`
- `Logiciels Utiles/` — 87 scripts `.bat` répartis en 17 catégories
- `Ressources/_core.bat` — bibliothèque partagée (`:AdminCheck`, `:LogoHeader`, `:DoInstall`, `:DoUpdate`, `:Countdown`, `:Log`)
- `Ressources/qc-check.py` / `qc-check.sh` — contrôle qualité avant release
- `Ressources/` — ressources téléchargées par certains scripts (archive DS4 Windows, profil Winhance, capture du dossier)

**99 fichiers** publiés. Contrôle qualité exécuté au moment de la publication : **0 erreur, 13
avertissements, 4 infos** — « SUCCÈS — Tous les fichiers .bat passent le contrôle qualité »
(86 fichiers `.bat` vérifiés en CRLF).

## Non versionné volontairement

`*.tmp`, `*.log` (dont `Ressources/install.log`), caches Python et fichiers système Windows/macOS —
voir `.gitignore`. Les fichiers `test*.tmp` présents à la racine sont restés sur le disque.

## Points à savoir

- `Ressources/DS4 Windows by Mathys M.7z` pèse **79,5 Mo** : GitHub l'accepte (limite dure 100 Mo) mais
  affiche un avertissement et recommande Git LFS au-delà de 50 Mo.
- `Ressources/qc-check.py` et `qc-check.sh` cherchent le dossier `Logiciels Utiles by Mathys M`, alors
  que le dossier s'appelle `Logiciels Utiles` sur le disque : le QC échoue tel quel
  (« Aucun fichier .bat trouvé »). Les deux constantes `BATCH_DIR` sont à corriger pour que le script
  fonctionne à nouveau.
- Plusieurs scripts téléchargent leurs ressources depuis `https://MathysM-Yt.github.io/Logiciels-Utiles/Ressources/...`
  (GitHub Pages du compte d'origine) — ce dépôt-ci est une copie, pas la source de ces URLs.

## Mettre à jour

```bash
cd "C:/Users/DYNOX2.0/Documents/worspace/logiciel utile/Logiciels-Utiles-1.1.0"
git add -A && git commit -m "…" && git push
```
