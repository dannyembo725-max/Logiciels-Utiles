#!/usr/bin/env python3
"""
refactor-to-core.py — Refactorise les scripts .bat vers _core.bat

Transforme les scripts suivant le pattern standard (4 options : Présentation,
Github, Install, Update) pour utiliser la bibliothèque partagée _core.bat.

Usage :
    python3 Ressources/refactor-to-core.py             # Dry-run, montre ce qui changerait
    python3 Ressources/refactor-to-core.py --apply      # Applique les changements
"""

import os
import re
import sys

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
BATCH_DIR = os.path.join(PROJECT_ROOT, "Logiciels Utiles by Mathys M")
CORE_PATH = os.path.join(SCRIPT_DIR, "_core.bat")

# Fichiers infrastructural (ne pas toucher)
INFRA_FILES = {
    "Logiciels Utiles.bat",
    "Installation par catégorie.bat",
}

# Scripts spéciaux (menus étendus, choco, URLs, etc.) — à ne pas refactorer
SKIP_FILES = {
    "Gaming/DS4 Windows.bat",
    "Gaming/Project GLD.bat",
    "Gaming/Carte graphique/Radeon Software Slimmer.bat",
    "Gaming/Cloud Gaming/Boosteroid.bat",
    "Gaming/Cloud Gaming/GeForce Now.bat",
    "Audio/Dolby.bat",
    "Optimisation/Winhance.bat",
    "Navigateur/Sine.bat",
    "Navigateur/Extensions/Enhancer for YouTube.bat",
    "Navigateur/Extensions/Streaming Enhanced.bat",
    "Audio/Nvidia Broadcast.bat",
    "Gaming/Carte graphique/Nvidia/Nvidia Profile Inspector.bat",
    "Apparence/Spicetify.bat",
    "Apparence/Wallpaper Engine.bat",
    "Gaming/Lossless Scaling.bat",
    "Diagnostic/MemTest86.bat",
    "Productivité/App Group.bat",
    "Productivité/File Pilot.bat",
    "Stream/OBS Multi RTMP.bat",
}


def find_bat_files(root):
    """Collecte tous les .bat excluant l'infra et _core.bat lui-même."""
    files = []
    for dp, dn, fn in os.walk(root):
        for f in fn:
            if f.endswith(".bat") and f != "_core.bat":
                relpath = os.path.relpath(os.path.join(dp, f), root)
                if relpath not in INFRA_FILES:
                    files.append(os.path.join(dp, f))
    return sorted(files)


def get_relative_core_path(filepath):
    """Calcule le chemin relatif de _core.bat depuis le script."""
    script_dir = os.path.dirname(filepath)
    # Compter la profondeur depuis BATCH_DIR
    rel_to_batch = os.path.relpath(script_dir, BATCH_DIR)
    depth = 0 if rel_to_batch == "." else rel_to_batch.count(os.sep) + 1
    # +1 pour remonter de BATCH_DIR vers PROJECT_ROOT (où est Ressources/)
    ups = "..\\" * (depth + 1)
    # Prefixe %~dp0 : chemin absolu, independant du repertoire courant
    return f"%~dp0{ups}Ressources\\_core.bat"


def extract_config(content):
    """Extrait les variables de configuration du bloc [Config du script]."""
    config = {}
    patterns = {
        "Logiciel": r'^set\s+"Logiciel=(.+)"\s*$',
        "Presentation": r'^set\s+"Presentation=(.+)"\s*$',
        "Github": r'^set\s+"Github=(.+)"\s*$',
        "Install": r'^set\s+"Install=(.+)"\s*$',
        "Update": r'^set\s+"Update=(.+)"\s*$',
    }
    for key, pattern in patterns.items():
        m = re.search(pattern, content, re.MULTILINE)
        if m:
            config[key] = m.group(1)
    return config


def is_standard_script(content):
    """Vérifie si le script suit le pattern standard (4 options avec Update)."""
    checks = [
        r'echo\s+1\.\s+Présentation',
        r'echo\s+2\.\s+Site officiel',
        r'echo\s+3\.\s+Installation',
        r'echo\s+4\.\s+Mettre',
        r'CHOICE\s+/C\s+1234',
        r':Menu',
        r':Presentation',
        r':Github',
        r':Install',
        r':Update',
        r'%Install%',
        r'%Update%',
    ]
    return all(re.search(c, content, re.MULTILINE) for c in checks)


def generate_refactored(config, core_rel_path):
    """Génère le nouveau contenu du script."""
    has_update = "Update" in config

    lines = [
        "@echo off",
        "chcp 65001 >nul",
        "setlocal EnableExtensions",
        "CLS",
        "",
        ":: =============",
        ":: Config du script",
        ":: =============",
        "",
        f'set "Logiciel={config["Logiciel"]}"',
        "",
        ":: Vidéo Youtube",
        f'set "Presentation={config["Presentation"]}"',
        "",
        ":: Site officiel / Github",
        f'set "Github={config["Github"]}"',
        "",
        ":: Installation automatique",
        f'set "Install={config["Install"]}"',
    ]

    if has_update:
        lines.append(f':: Mise à jour automatique')
        lines.append(f'set "Update={config["Update"]}"')

    lines.extend([
        "",
        ":: ============",
        ":: Fin de la config",
        ":: ============",
        "",
        "",
        ":: Bibliothèque partagée (_core.bat)",
        f'set "_CORE={core_rel_path}"',
        "",
        ":: Vérification des droits administrateur",
        'call "%_CORE%" :AdminCheck "%~f0"',
        'if %errorlevel% neq 0 exit /b 1',
        "",
        ":Menu",
        "CLS",
        "",
        f'title %Logiciel% - Menu',
        "",
        'call "%_CORE%" :LogoHeader',
        "",
        "echo 1. Présentation",
            "echo 2. Site officiel / Github",
            "echo 3. Installation automatique",
    ])

    if has_update:
        lines.extend([
            "echo 4. Mettre à jour",
            "echo.",
            "",
            'CHOICE /C 1234 /M "Entre ton choix:"',
            "",
            "IF ERRORLEVEL 4 GOTO Update",
            "IF ERRORLEVEL 3 GOTO Install",
            "IF ERRORLEVEL 2 GOTO Github",
            "IF ERRORLEVEL 1 GOTO Presentation",
        ])
    else:
        lines.extend([
            "echo.",
            "",
            'CHOICE /C 123 /M "Entre ton choix:"',
            "",
            "IF ERRORLEVEL 3 GOTO Install",
            "IF ERRORLEVEL 2 GOTO Github",
            "IF ERRORLEVEL 1 GOTO Presentation",
        ])

    lines.extend([
        "",
        "",
        ":Presentation",
        "CLS",
        "",
        'start "" "%Presentation%"',
        "",
        "GOTO Menu",
        "",
        "",
        ":Github",
        "CLS",
        "",
        'start "" "%Github%"',
        "",
        "GOTO Menu",
        "",
        "",
        ":Update",
        "call \"%_CORE%\" :DoUpdate",
        "GOTO Menu",
        "",
        "",
        ":Install",
        "call \"%_CORE%\" :DoInstall",
        "GOTO Menu",
        "",
    ])

    return "\r\n".join(lines) + "\r\n"


def main():
    apply = "--apply" in sys.argv
    mode = "APPLY" if apply else "DRY-RUN"

    print(f"[{mode}] Refactorisation vers _core.bat")
    print(f"  BATCH_DIR : {BATCH_DIR}")
    print(f"  _core.bat : {CORE_PATH}")
    print()

    bat_files = find_bat_files(BATCH_DIR)
    to_refactor = []
    skipped_special = []
    skipped_non_standard = []

    for filepath in bat_files:
        relpath = os.path.relpath(filepath, BATCH_DIR)

        relpath_norm = relpath.replace(os.sep, '/')
        if relpath_norm in SKIP_FILES:
            skipped_special.append(relpath)
            continue

        with open(filepath, "r", encoding="utf-8", errors="replace") as f:
            content = f.read()

        if not is_standard_script(content):
            skipped_non_standard.append(relpath)
            continue

        to_refactor.append(filepath)

    print(f"À refactorer : {len(to_refactor)} scripts")
    print(f"Spéciaux (skip): {len(skipped_special)} scripts")
    print(f"Non-standard (skip): {len(skipped_non_standard)} scripts")
    print()

    for fp in to_refactor:
        relpath = os.path.relpath(fp, BATCH_DIR)
        config = extract_config(open(fp, encoding="utf-8", errors="replace").read())
        core_rel = get_relative_core_path(fp)

        if apply:
            new_content = generate_refactored(config, core_rel)
            with open(fp, "w", encoding="utf-8-sig", newline="") as f:
                f.write(new_content)
            print(f"  + {relpath}")
        else:
            print(f"  -> {relpath}  (core: {core_rel})")

    print()
    if skipped_special:
        print(f"Spéciaux ignorés ({len(skipped_special)}):")
        for s in skipped_special:
            print(f"  • {s}")
    if skipped_non_standard:
        print(f"Non-standard ignorés ({len(skipped_non_standard)}):")
        for s in skipped_non_standard:
            print(f"  • {s}")

    print()
    if apply:
        print(f"[APPLY] {len(to_refactor)} scripts refactorisés.")
    else:
        print(f"[DRY-RUN] {len(to_refactor)} scripts seront refactorisés.")
        print("Relancez avec --apply pour écrire les changements.")


if __name__ == "__main__":
    main()
