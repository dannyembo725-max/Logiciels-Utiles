#!/usr/bin/env bash
#
# qc-check.sh — Script de contrôle qualité pour "Logiciels Utiles by Mathys M"
# Vérifie la cohérence de tous les scripts .bat avant une release.
#
# Usage :  ./Ressources/qc-check.sh
#          ou  bash Ressources/qc-check.sh
#
# Exigeances : bash, python3 (pour l'analyse détaillée)
#
# Ce que le script vérifie :
#   1. Extensions de ligne CRLF (obligatoire pour cmd.exe)
#   2. Cohérence des labels : tout `goto :Label` a un `:Label` correspondant
#   3. Cohérence CHOICE / ERRORLEVEL : chaque chiffre dans CHOICE /C correspond
#      à un `IF ERRORLEVEL N GOTO Label`
#   4. Format des commandes winget (Install et Update)
#   5. Détection des scripts non-winget (pris en charge ou signalés par l'installeur)
#   6. Présence de la variable Logiciel= (obligatoire)
#   7. Présence des labels de menu standard (Menu / Presentation / Github)
#   8. Appel :AdminCheck transmettant le chemin du script ("%~f0")
#
set -euo pipefail

# ── Configuration ──────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BATCH_DIR="$PROJECT_ROOT/Logiciels Utiles by Mathys M"

# Fichiers infrastructural qui n'ont pas de variables Install/Update
INFRA_FILES=(
    "Logiciels Utiles.bat"
    "Installation par catégorie.bat"
)

ERRORS=()
WARNINGS=()
INFO=()

# ── Couleurs ───────────────────────────────────────────────────────────────
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ── Helpers ────────────────────────────────────────────────────────────────
is_infra_file() {
    local relpath="$1"
    for infra in "${INFRA_FILES[@]}"; do
        if [[ "$relpath" == "$infra" ]]; then
            return 0
        fi
    done
    return 1
}

add_error()   { ERRORS+=("$1"); }
add_warning() { WARNINGS+=("$1"); }
add_info()    { INFO+=("$1"); }

# ── Collecte des fichiers .bat ─────────────────────────────────────────────
mapfile -t BAT_FILES < <(find "$BATCH_DIR" -name '*.bat' | sort)

if [[ ${#BAT_FILES[@]} -eq 0 ]]; then
    echo -e "${RED}Aucun fichier .bat trouvé dans $BATCH_DIR${NC}"
    exit 1
fi

echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Logiciels Utiles — Contrôle Qualité (QC)                     ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Répertoire : $BATCH_DIR"
echo "Fichiers .bat détectés : ${#BAT_FILES[@]}"
echo ""

# ── Vérification 1: CRLF ───────────────────────────────────────────────────
echo -e "${BLUE}[$(date +%H:%M:%S)] Vérification 1/7 : Extensions de ligne CRLF${NC}"
crlf_violations=()
for f in "${BAT_FILES[@]}"; do
    # Vérifie si le fichier contient des CRLF
    if ! python3 -c "
import sys
with open(sys.argv[1], 'rb') as fh:
    data = fh.read()
has_crlf = b'\r\n' in data
has_lf_only = b'\n' in data and not has_crlf
sys.exit(1 if has_lf_only else 0)
" "$f" 2>/dev/null; then
        relpath="${f#$BATCH_DIR/}"
        crlf_violations+=("$relpath")
        add_error "Fichier $relpath : fin de ligne LF (Unix) — doit être CRLF"
    fi
done

if [[ ${#crlf_violations[@]} -eq 0 ]]; then
    echo -e "  ${GREEN}✓ Tous les fichiers sont en CRLF${NC}"
else
    echo -e "  ${RED}✗ ${#crlf_violations[@]} fichier(s) en LF :${NC}"
    for v in "${crlf_violations[@]}"; do
        echo "    - $v"
    done
fi
echo ""

# ── Analyse détaillée avec Python ───────────────────────────────────────────
# Python fait l'analyse lexicale des labels, CHOICE/ERRORLEVEL, etc.
set +e
PY_OUTPUT=$(python3 - "$BATCH_DIR" "${INFRA_FILES[@]}" <<'PYEOF'
import os, re, sys

batch_dir = sys.argv[1]
infra_files = sys.argv[2:]

errors = []
warnings = []
infos = []

# Collecte des fichiers .bat
bat_files = []
for dp, dn, fn in os.walk(batch_dir):
    for f in fn:
        if f.endswith('.bat'):
            bat_files.append(os.path.join(dp, f))
bat_files.sort()

for filepath in bat_files:
    relpath = os.path.relpath(filepath, batch_dir)
    is_infra = relpath in infra_files

    with open(filepath, 'r', encoding='utf-8', errors='replace') as fh:
        content = fh.read()
    lines = content.splitlines()

    # ── Vérif 6: Variable Logiciel= ───────────────────────────────────────
    if not is_infra and not re.search(r'^set\s+"Logiciel=', content, re.MULTILINE):
        errors.append(f"{relpath} : variable 'Logiciel=' manquante (utilisée pour le titre)")

    # ── Vérif 7: Labels de menu standard ──────────────────────────────────
    # Les scripts logiciels doivent avoir :Menu, :Presentation, :Github
    if not is_infra:
        for label in [':Menu', ':Presentation', ':Github']:
            if label not in content:
                # Vérifier aussi le format :Label
                if not re.search(rf'^{re.escape(label)}\s', content, re.MULTILINE):
                    warnings.append(f"{relpath} : label '{label}' non trouvé (menu standard incomplet)")

    # ── Analyse des goto / labels ─────────────────────────────────────────
    labels = set()
    gotos = []
    choice_patterns = []
    errorlevel_patterns = []
    install_lines = []
    update_lines = []

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
            # Extraire les chiffres valides
            digits = re.findall(r'\d', choice_chars)
            choice_patterns.append((i, digits))

        # IF ERRORLEVEL N GOTO Label
        m = re.match(r'^IF\s+ERRORLEVEL\s+(\d+)\s+GOTO\s+:?(\w+)', stripped, re.IGNORECASE)
        if m:
            errorlevel_patterns.append((i, int(m.group(1)), m.group(2)))

        # set "Install=..." ou set "Update=..."
        m = re.match(r'^set\s+"(Install|Update)=(.+)"\s*$', stripped)
        if m:
            var_name, cmd = m.group(1), m.group(2)
            if var_name == 'Install':
                install_lines.append((i, cmd))
            elif var_name == 'Update':
                update_lines.append((i, cmd))

    # ── Vérif 2: Cohérence goto / labels ──────────────────────────────────
    for lineno, target in gotos:
        if target not in labels:
            # goto vers un label inexistant
            errors.append(f"{relpath} ligne {lineno} : 'goto :{target}' — label ':{target}' non défini")

    # ── Vérif 3: Cohérence CHOICE / ERRORLEVEL ────────────────────────────
    for choice_lineno, digits in choice_patterns:
        if not digits:
            continue

        # Trouver tous les IF ERRORLEVEL suivant ce CHOICE
        # (on regarde tous les ERRORLEVEL du fichier, mais on peut vérifier
        # que chaque digit a son gestionnaire)
        # Stratégie: extraire tous les ERRORLEVEL values uniques
        all_errorlevels = set(el for _, el, _ in errorlevel_patterns)

        for d in digits:
            if d not in all_errorlevels:
                # C'est peut-être une entrée de retour (0), qui n'a pas de ERRORLEVEL
                # car elle est gérée par `if "!c!"=="0" goto Up`
                pass  # Pas forcément une erreur pour les scripts non-CHOICE

    # Vérification plus stricte: pour chaque CHOICE avec des chiffres,
    # chaque chiffre > 0 doit avoir un IF ERRORLEVEL correspondant
    for choice_lineno, digits in choice_patterns:
        matching_levels = [el for ln, el, _ in errorlevel_patterns
                           if ln > choice_lineno]
        for d in digits:
            d_int = int(d)
            if d_int > 0 and d_int not in matching_levels:
                errors.append(
                    f"{relpath} ligne {choice_lineno} : "
                    f"CHOICE /C inclut '{d}' mais aucun "
                    f"'IF ERRORLEVEL {d_int} GOTO' trouvé après le CHOICE"
                )

    # ── Vérif 4: Format winget Install/Update ─────────────────────────────
    for lineno, cmd in install_lines:
        if 'winget' in cmd:
            # Vérifier que c'est une commande install
            if 'install' not in cmd:
                errors.append(
                    f"{relpath} ligne {lineno} : Install= contient 'winget' "
                    f"mais pas 'install' → {cmd[:80]}..."
                )
            # Vérifier qu'il n'y a pas --force dans install (optionnel mais recommandé de le garder)
            if '--force' not in cmd:
                infos.append(
                    f"{relpath} ligne {lineno} : Install= winget sans '--force' "
                    f"(normal si --accept-package-agreements est présent)"
                )
        elif 'choco' in cmd:
            infos.append(
                f"{relpath} ligne {lineno} : Install= utilise choco "
                f"(Chocolatey installé au besoin par l'installeur)"
            )
        elif cmd.startswith('http'):
            infos.append(
                f"{relpath} ligne {lineno} : Install= est une URL directe "
                f"(l'installeur ouvre la page dans le navigateur)"
            )
        elif not cmd.startswith('winget') and not cmd.startswith('choco'):
            # Vérifier si c'est une commande PowerShell inline
            if 'powershell' in cmd.lower() or 'cmd' in cmd.lower():
                infos.append(
                    f"{relpath} ligne {lineno} : Install= utilise une "
                    f"commande personnalisée (powershell/cmd)"
                )

    for lineno, cmd in update_lines:
        if 'winget' in cmd:
            if 'upgrade' not in cmd:
                errors.append(
                    f"{relpath} ligne {lineno} : Update= contient 'winget' "
                    f"mais pas 'upgrade' → {cmd[:80]}..."
                )
            if '--force' in cmd:
                errors.append(
                    f"{relpath} ligne {lineno} : Update= contient '--force' "
                    f"(devrait être retiré pour les mises à jour)"
                )

    # ── Vérif 8: appel :AdminCheck avec le chemin du script ──────────────
    # Sans "%~f0", _core relancerait _core.bat au lieu du script appelant.
    if not is_infra:
        for m in re.finditer(r'call\s+"%_CORE%"\s+:AdminCheck([^\r\n]*)', content):
            if '"%~f0"' not in m.group(1):
                errors.append(
                    f"{relpath} : appel ':AdminCheck' sans \"%~f0\" — "
                    f"l'élévation relancerait _core.bat au lieu du script"
                )

    # ── Vérif: scripts sans Install ni Update ni Download ──────────────────
    if not is_infra:
        has_install = any(True for _ in install_lines)
        has_update = any(True for _ in update_lines)
        has_download = bool(re.search(r'^set\s+"Download=', content, re.MULTILINE))

        if not has_install and not has_update and not has_download:
            warnings.append(
                f"{relpath} : Aucune variable Install/Update/Download — "
                f"script ignoré par l'installeur par catégorie"
            )

# Sortie des résultats
for e in errors:
    print(f"ERROR|{e}")
for w in warnings:
    print(f"WARNING|{w}")
for i in infos:
    print(f"INFO|{i}")

# Exit code
if errors:
    sys.exit(1)
PYEOF
)

# ── Affichage des résultats ────────────────────────────────────────────────
err_count=$(printf '%s\n' "$PY_OUTPUT" | grep -c '^ERROR|' || true)
warn_count=$(printf '%s\n' "$PY_OUTPUT" | grep -c '^WARNING|' || true)
info_count=$(printf '%s\n' "$PY_OUTPUT" | grep -c '^INFO|' || true)

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║  Résumé${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════╝${NC}"
echo -e "  ${BOLD}Erreurs  :${NC} ${RED}${err_count}${NC}"
echo -e "  ${BOLD}Avert.   :${NC} ${YELLOW}${warn_count}${NC}"
echo -e "  ${BOLD}Infos    :${NC} ${info_count}"
echo ""

if [[ "$err_count" -gt 0 ]]; then
    echo -e "${BOLD}ERREURS${NC}"
    echo "────────────────────────────────────────────────────────────"
    printf '%s\n' "$PY_OUTPUT" | sed -n 's/^ERROR|/  • /p'
    echo ""
fi
if [[ "$warn_count" -gt 0 ]]; then
    echo -e "${BOLD}AVERTISSEMENTS${NC}"
    echo "────────────────────────────────────────────────────────────"
    printf '%s\n' "$PY_OUTPUT" | sed -n 's/^WARNING|/  • /p'
    echo ""
fi
if [[ "$info_count" -gt 0 ]]; then
    echo -e "${BOLD}INFOS (scripts non-standard)${NC}"
    echo "────────────────────────────────────────────────────────────"
    printf '%s\n' "$PY_OUTPUT" | sed -n 's/^INFO|/  • /p'
    echo ""
fi

echo "────────────────────────────────────────────────────────────────────────"
if [[ "$err_count" -gt 0 ]]; then
    echo -e "${RED}${BOLD}✗ ÉCHEC — ${err_count} erreur(s) détectée(s)${NC}"
    exit 1
else
    echo -e "${GREEN}${BOLD}✓ SUCCÈS — Tous les fichiers .bat passent le contrôle qualité${NC}"
    exit 0
fi
