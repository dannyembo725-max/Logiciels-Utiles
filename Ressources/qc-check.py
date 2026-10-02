#!/usr/bin/env python3
"""
qc-check.py — Contrôle qualité pour "Logiciels Utiles by Mathys M"

Vérifie la cohérence de tous les scripts .bat avant une release.

Usage :
    python3 Ressources/qc-check.py
    python3 Ressources/qc-check.py --fix-crlf   # tente de corriger automatiquement les LF → CRLF

Vérifications :
    1. Extensions de ligne CRLF (obligatoire pour cmd.exe)
    2. Cohérence goto / labels (chaque `goto :Label` a un `:Label` correspondant)
    3. Cohérence CHOICE /C / ERRORLEVEL (chaque chiffre a son gestionnaire)
    4. Format des commandes winget (Install → install, Update → upgrade, pas --force)
    5. Détection des scripts non-winget (URLs, choco, personnalisés)
    6. Variable `Logiciel=` obligatoire
    7. Labels de menu standard (:Menu, :Presentation, :Github)
    8. Appel `:AdminCheck` transmettant le chemin du script ("%~f0")
"""

import os
import re
import sys
from datetime import datetime

# ── Configuration ──────────────────────────────────────────────────────────

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT = os.path.dirname(SCRIPT_DIR)
BATCH_DIR = os.path.join(PROJECT_ROOT, "Logiciels Utiles by Mathys M")

# Fichiers infrastructural qui n'ont pas de variables Install/Update
INFRA_FILES = {
    "Logiciels Utiles.bat",
    "Installation par catégorie.bat",
}

# ── Forcer l'encodage UTF-8 sur la sortie standard (nécessaire sur Windows) ──
try:
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
except AttributeError:
    pass  # Python < 3.7 — passthrough


# ── Couleurs ───────────────────────────────────────────────────────────────

RED = "\033[0;31m"
YELLOW = "\033[1;33m"
GREEN = "\033[0;32m"
BLUE = "\033[0;34m"
BOLD = "\033[1m"
NC = "\033[0m"  # No Color


class QCResult:
    def __init__(self):
        self.errors = []
        self.warnings = []
        self.infos = []

    def error(self, msg):
        self.errors.append(msg)

    def warning(self, msg):
        self.warnings.append(msg)

    def info(self, msg):
        self.infos.append(msg)

    @property
    def has_errors(self):
        return len(self.errors) > 0


def find_bat_files(root):
    """Collecte tous les fichiers .bat en profondeur, triés."""
    files = []
    for dp, dn, fn in os.walk(root):
        for f in fn:
            if f.endswith(".bat"):
                files.append(os.path.join(dp, f))
    return sorted(files)


def check_crlf(filepath, result):
    """Vérifie que le fichier utilise des fins de ligne CRLF."""
    with open(filepath, "rb") as fh:
        data = fh.read()
    has_crlf = b"\r\n" in data
    has_lf_only = b"\n" in data and not has_crlf
    if has_lf_only:
        relpath = os.path.relpath(filepath, BATCH_DIR)
        result.error(
            f"{relpath} : fin de ligne LF (Unix) — cmd.exe ne trouvera pas "
            f"les labels (goto). Convertir en CRLF."
        )
        return False
    return True


def fix_crlf(filepath):
    """Convertit les fins de ligne LF en CRLF."""
    with open(filepath, "rb") as fh:
        data = fh.read()
    # Normaliser : retirer tous les CR existants, puis ajouter CR avant chaque LF
    data = data.replace(b"\r\r\n", b"\n")
    data = data.replace(b"\r\n", b"\n")
    data = data.replace(b"\r", b"\n")
    data = data.replace(b"\n", b"\r\n")
    with open(filepath, "wb") as fh:
        fh.write(data)


def analyze_script(filepath, result):
    """Analyse un fichier .bat pour la cohérence des labels, CHOICE, winget, etc."""
    relpath = os.path.relpath(filepath, BATCH_DIR)
    is_infra = relpath in INFRA_FILES

    with open(filepath, "r", encoding="utf-8", errors="replace") as fh:
        content = fh.read()
    lines = content.splitlines()

    # ── Vérif 6: Variable Logiciel= ────────────────────────────────────────
    if not is_infra:
        if not re.search(r'^set\s+"Logiciel=', content, re.MULTILINE):
            result.error(f"{relpath} : variable 'Logiciel=' manquante")

    # ── Vérif 7: Labels de menu standard ──────────────────────────────────
    if not is_infra:
        for label in [":Menu", ":Presentation", ":Github"]:
            if not re.search(rf'^{re.escape(label)}\s*$', content, re.MULTILINE):
                result.warning(f"{relpath} : label '{label}' non trouvé (menu standard incomplet)")

    # ── Extraction des éléments clés ──────────────────────────────────────
    labels = set()
    gotos = []          # (lineno, target)
    choice_patterns = []  # (lineno, [digits])
    errorlevel_patterns = []  # (lineno, int_level, label)
    install_lines = []    # (lineno, cmd)
    update_lines = []     # (lineno, cmd)

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Labels :Label
        m = re.match(r'^:(\w+)', stripped)
        if m:
            labels.add(m.group(1))

        # goto :Label ou goto Label
        m = re.match(r'^goto\s+:?(\w+)', stripped, re.IGNORECASE)
        if m:
            gotos.append((i, m.group(1)))

        # CHOICE /C 1234 /M "..."
        m = re.search(r'CHOICE\s+/C\s+(\S+)', stripped, re.IGNORECASE)
        if m:
            choice_chars = m.group(1)
            digits = re.findall(r"\d", choice_chars)
            if digits:
                choice_patterns.append((i, digits))

        # IF ERRORLEVEL N GOTO Label
        m = re.match(r'^IF\s+ERRORLEVEL\s+(\d+)\s+GOTO\s+:?(\w+)', stripped, re.IGNORECASE)
        if m:
            errorlevel_patterns.append((i, int(m.group(1)), m.group(2)))

        # set "Install=..." ou set "Update=..."
        m = re.match(r'^set\s+"(Install|Update)=(.+)"\s*$', stripped)
        if m:
            var_name, cmd = m.group(1), m.group(2)
            if var_name == "Install":
                install_lines.append((i, cmd))
            elif var_name == "Update":
                update_lines.append((i, cmd))

    # ── Vérif 2: goto → label existence ──────────────────────────────────
    for lineno, target in gotos:
        if target not in labels:
            result.error(
                f"{relpath} ligne {lineno} : "
                f"'goto :{target}' — label ':{target}' non défini"
            )

    # ── Vérif 3: CHOICE /C → IF ERRORLEVEL ────────────────────────────────
    # Pour chaque CHOICE avec des chiffres, chaque chiffre (>0) doit avoir
    # un 'IF ERRORLEVEL N GOTO' correspondant APRÈS le CHOICE.
    for choice_lineno, digits in choice_patterns:
        matching_levels = [
            el for ln, el, _ in errorlevel_patterns if ln > choice_lineno
        ]
        for d in digits:
            d_int = int(d)
            if d_int > 0 and d_int not in matching_levels:
                result.error(
                    f"{relpath} ligne {choice_lineno} : "
                    f"CHOICE /C inclut '{d}' mais aucun "
                    f"'IF ERRORLEVEL {d_int} GOTO' trouvé après le CHOICE"
                )

    # ── Vérif 4: Format winget Install/Update ─────────────────────────────
    for lineno, cmd in install_lines:
        if "winget" in cmd:
            if "install" not in cmd:
                result.error(
                    f"{relpath} ligne {lineno} : Install= contient 'winget' "
                    f"mais pas 'install' — {cmd[:80]}"
                )
        elif "choco" in cmd:
            result.info(
                f"{relpath} ligne {lineno} : Install= utilise choco "
                f"(l'installeur par catégorie installe Chocolatey au besoin puis exécute la commande)"
            )
        elif cmd.startswith("http"):
            result.info(
                f"{relpath} ligne {lineno} : Install= est une URL directe "
                f"(l'installeur par catégorie ouvre la page de téléchargement dans le navigateur)"
            )
        elif not cmd.startswith("winget"):
            if "powershell" in cmd.lower() or "start" in cmd.lower():
                result.info(
                    f"{relpath} ligne {lineno} : Install= utilise une "
                    f"commande personnalisée (powershell/start — installation manuelle)"
                )

    for lineno, cmd in update_lines:
        if "winget" in cmd:
            if "upgrade" not in cmd:
                result.error(
                    f"{relpath} ligne {lineno} : Update= contient 'winget' "
                    f"mais pas 'upgrade' — {cmd[:80]}"
                )
            if "--force" in cmd:
                result.error(
                    f"{relpath} ligne {lineno} : Update= contient '--force' "
                    f"(devrait être retiré pour les mises à jour)"
                )
        elif "choco" in cmd:
            result.info(
                f"{relpath} ligne {lineno} : Update= utilise choco (non-standard)"
            )

    # ── Vérif 8: appel :AdminCheck avec le chemin du script appelant ────
    # Sans "%~f0", _core relauncher _core.bat au lieu du script.
    if not is_infra:
        for m in re.finditer(r'call\s+"%_CORE%"\s+:AdminCheck([^\r\n]*)', content):
            if '"%~f0"' not in m.group(1):
                result.error(
                    f"{relpath} : appel ':AdminCheck' sans \"%~f0\" — "
                    f"l'élévation relancerait _core.bat au lieu du script"
                )

    # ── Vérif 5 & edge case: scripts sans Install/Update/Download ────────
    if not is_infra:
        has_install = len(install_lines) > 0
        has_update = len(update_lines) > 0
        has_download = bool(re.search(r'^set\s+"Download=', content, re.MULTILINE))

        if not has_install and not has_update and not has_download:
            result.warning(
                f"{relpath} : Aucune variable Install/Update/Download — "
                f"script ignoré par l'installeur par catégorie"
            )


def print_section(title, items, color=BLUE):
    if items:
        print(f"\n{BOLD}{title}{NC}")
        print("─" * 60)
        for item in items:
            print(f"  {color}•{NC} {item}")
    else:
        print(f"  {GREEN}✓ Aucune{NC}")


def main():
    fix_crlf_mode = "--fix-crlf" in sys.argv

    print(f"{BOLD}╔══════════════════════════════════════════════════════════════╗{NC}")
    print(f"{BOLD}║  Logiciels Utiles — Contrôle Qualité (QC)                     ║{NC}")
    print(f"{BOLD}╚══════════════════════════════════════════════════════════════╝{NC}")
    print()
    print(f"Répertoire : {BATCH_DIR}")

    bat_files = find_bat_files(BATCH_DIR)
    if not bat_files:
        print(f"{RED}Aucun fichier .bat trouvé dans {BATCH_DIR}{NC}")
        sys.exit(1)

    infra_count = sum(1 for f in bat_files if os.path.relpath(f, BATCH_DIR) in INFRA_FILES)
    software_count = len(bat_files) - infra_count
    print(f"Fichiers .bat détectés : {len(bat_files)} "
          f"({software_count} logiciels + {infra_count} infra)")
    print()

    result = QCResult()

    # ── Vérif 1: CRLF ────────────────────────────────────────────────────
    print(f"{BLUE}[{_now()}] Vérification 1/7 : Extensions de ligne CRLF{NC}")
    crlf_ok = 0
    crlf_bad = 0
    for f in bat_files:
        relpath = os.path.relpath(f, BATCH_DIR)
        if check_crlf(f, result):
            crlf_ok += 1
        else:
            crlf_bad += 1

    if crlf_bad > 0:
        print(f"  {RED}✗ {crlf_bad} fichier(s) en LF (Unix){NC}")
        if fix_crlf_mode:
            for f in bat_files:
                relpath = os.path.relpath(f, BATCH_DIR)
                try:
                    with open(f, "rb") as fh:
                        data = fh.read()
                    if b"\r\n" not in data and b"\n" in data:
                        fix_crlf(f)
                        print(f"  {GREEN}→ {relpath} : converti en CRLF{NC}")
                except Exception as e:
                    print(f"  {RED}→ {relpath} : erreur — {e}{NC}")
            # Re-check
            result2 = QCResult()
            for f in bat_files:
                check_crlf(f, result2)
            if not result2.errors:
                print(f"  {GREEN}✓ Tous les fichiers sont maintenant en CRLF{NC}")
        else:
            print(f"  {YELLOW}→ Relancez avec --fix-crlf pour corriger automatiquement{NC}")
    else:
        print(f"  {GREEN}✓ Tous les {crlf_ok} fichiers sont en CRLF{NC}")

    # ── Analyse détaillée ────────────────────────────────────────────────
    print()
    print(f"{BLUE}Vérifications 2-7 : Analyse syntaxique et logique{NC}")
    for f in bat_files:
        analyze_script(f, result)

    # ── Résultats ────────────────────────────────────────────────────────
    print()
    print(f"{BOLD}╔══════════════════════════════════════════════════════════════╗{NC}")
    print(f"{BOLD}║  Résumé{NC}")
    print(f"{BOLD}╚══════════════════════════════════════════════════════════════╝{NC}")
    print(f"  {BOLD}Erreurs  :{NC} {RED}{len(result.errors)}{NC}")
    print(f"  {BOLD}Avert.   :{NC} {YELLOW}{len(result.warnings)}{NC}")
    print(f"  {BOLD}Infos    :{NC} {len(result.infos)}")
    print()

    print_section("⚠️  ERREURS (à corriger impérativement)", result.errors, RED)
    print_section("⚠️  AVERTISSEMENTS", result.warnings, YELLOW)
    print_section("ℹ️  INFOS (scripts non-standard)", result.infos, "")

    print()
    print("─" * 60)
    if result.has_errors:
        print(f"{RED}{BOLD}✗ ÉCHEC — {len(result.errors)} erreur(s) détectée(s){NC}")
        sys.exit(1)
    else:
        print(f"{GREEN}{BOLD}✓ SUCCÈS — Tous les fichiers .bat passent le contrôle qualité{NC}")
        sys.exit(0)


def _now():
    return datetime.now().strftime("%H:%M:%S")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print(f"\n{YELLOW}Interrompu par l'utilisateur{NC}")
        sys.exit(130)
