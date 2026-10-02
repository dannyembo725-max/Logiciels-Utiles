@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Logiciels Utiles by Mathys M - Lanceur
cd /d "%~dp0"
set "ROOT=%CD%"
set "CUR=%CD%"

:Show
cls
echo ============================================================
echo    Logiciels Utiles by Mathys M - Lanceur
echo ============================================================
echo  Dossier : !CUR!
echo  Taper 'S' puis Entree pour chercher un logiciel par nom
echo.
echo    [0] Retour
echo.
set /a n=0
set /a total_dir=0
:: Nettoyer les variables item[] de la boucle précédente
for /f "delims=" %%v in ('set item[ 2^>nul') do set "%%v="
:: Lister les dossiers avec compteur de logiciels
for /d %%D in ("!CUR!\*") do (
    set /a n+=1
    set "item[!n!]=%%~fD"
    :: Compter les .bat dans ce dossier et ses sous-dossiers
    set /a count=0
    for /f %%C in ('dir /b /s /a-d "%%~fD\*.bat" 2^>nul') do set /a count+=1
    set /a total_dir+=count
    if !count! gtr 1 (
        echo    [!n!] [Dossier] %%~nxD ^(!count! logiciels^)
    ) else if !count! equ 1 (
        echo    [!n!] [Dossier] %%~nxD ^(!count! logiciel^)
    ) else (
        echo    [!n!] [Dossier] %%~nxD ^(vide^)
    )
)
:: Lister les fichiers .bat du dossier courant
for %%F in ("!CUR!\*.bat") do (
    if /i not "%%~nxF"=="Logiciels Utiles.bat" (
        set /a n+=1
        set "item[!n!]=%%~fF"
        echo    [!n!] %%~nxF
    )
)
echo.
set "c="
set /p "c=   Ton choix : "
if not defined c goto Show
if /i "!c!"=="0" goto Up
if /i "!c!"=="S" goto Search
set "sel=!item[%c%]!"
if not defined sel goto Show
if exist "!sel!\*" (
    set "CUR=!sel!"
    goto Show
)
start "" "!sel!"
timeout /t 1 /nobreak >nul
goto Show

:Search
cls
echo ============================================================
echo    Recherche par nom
echo ============================================================
echo.
set /p "search=   Chercher : "
if not defined search goto Show
echo.
echo Resultats pour "!search!" :"
echo.
set /a n=0
for /f "delims=" %%v in ('set item_search[ 2^>nul') do set "%%v="
for /f "delims=" %%F in ('dir /s /b /a-d "!ROOT!\*.bat" 2^>nul') do (
    set "fn=%%~nxF"
    echo !fn! | findstr /i "!search!" >nul
    if !errorlevel! equ 0 (
        set /a n+=1
        set "item_search[!n!]=%%~fF"
        echo    [!n!] %%~nxF
    )
)
echo.
if !n! equ 0 (
    echo Aucun logiciel trouve.
    echo.
    pause
    goto Show
)
echo !n! resultat^(s^) trouve^(s^)
echo.
set /p "sel=   Choix (0 pour annuler) : "
if /i "!sel!"=="0" goto Show
set "s=!item_search[%sel%]!"
if not defined s goto Show
start "" "!s!"
timeout /t 1 /nobreak >nul
goto Show

:Up
if /i "!CUR!"=="!ROOT!" exit /b
for %%X in ("!CUR!\..") do set "CUR=%%~fX"
goto Show
