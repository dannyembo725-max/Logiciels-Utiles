@echo off
chcp 65001 >nul
setlocal EnableExtensions EnableDelayedExpansion
title Logiciels Utiles - Installation par categorie
cd /d "%~dp0"
set "ROOT=%CD%"

:: Bibliotheque partagee (_core.bat) - chemin absolu via %~dp0
set "_CORE=%~dp0..\Ressources\_core.bat"

:: Droits administrateur (on transmet le chemin du script pour l'elevation)
call "%_CORE%" :AdminCheck "%~f0"
if %errorlevel% neq 0 exit /b 1


:: ============================================================
::  Menu principal : liste des categories
:: ============================================================
:ChooseCat
cls
call "%_CORE%" :LogoHeader
echo ============================================================
echo    Installation par categorie
echo ============================================================
echo.
echo    Taper 'S' puis Entree pour chercher un logiciel par nom
echo.
set /a n=0
set /a total=0
for /f "delims==" %%v in ('set cat[ 2^>nul') do set "%%v="
for /d %%D in (*) do (
    set /a n+=1
    set "cat[!n!]=%%~fD"
    set /a cnt=0
    for /f %%C in ('dir /b /s /a-d "%%~fD\*.bat" 2^>nul') do set /a cnt+=1
    set /a total+=cnt
    if !cnt! gtr 1 (
        echo    [!n!] %%~nxD ^(!cnt! logiciels^)
    ) else if !cnt! equ 1 (
        echo    [!n!] %%~nxD ^(1 logiciel^)
    ) else (
        echo    [!n!] %%~nxD ^(vide^)
    )
)
echo.
echo    Total : !total! logiciels
echo    [0] Quitter
echo.
set "c="
set /p "c=   Ton choix : "
if not defined c goto ChooseCat
if /i "!c!"=="0" goto Quit
if /i "!c!"=="S" goto Search
set "sel=!cat[%c%]!"
if not defined sel goto ChooseCat
call :BrowseCat "!sel!"
goto ChooseCat


:: ============================================================
::  :BrowseCat <dossier> - liste les scripts d'une categorie
:: ============================================================
:BrowseCat
setlocal EnableExtensions EnableDelayedExpansion
cls
call "%_CORE%" :LogoHeader
echo ============================================================
echo    %~nx1
echo ============================================================
echo.
set /a n=0
for /f "delims==" %%v in ('set item[ 2^>nul') do set "%%v="
for /f "delims=" %%F in ('dir /b /s /a-d "%~f1\*.bat" 2^>nul') do (
    set /a n+=1
    set "item[!n!]=%%~fF"
    echo    [!n!] %%~nxF
)
echo.
if !n! lss 1 (
    echo    Aucun script dans ce dossier.
    echo.
    pause
    endlocal
    exit /b
)
echo    [0] Retour      [a] Tout installer
echo    Entre un numero, une liste (1,3,5) ou 'a'.
echo.
set "c="
set /p "c=   Ton choix : "
if not defined c goto BrowseDone
if /i "!c!"=="0" goto BrowseDone
if /i "!c!"=="a" (
    echo.
    echo    Installation de !n! logiciel^(s^)...
    for /l %%i in (1,1,!n!) do call :Install "!item[%%i]!"
    goto BrowseDone
)
for %%P in (!c!) do call :Install "!item[%%P]!"
:BrowseDone
echo.
pause
endlocal
exit /b


:: ============================================================
::  :Search - recherche globale par nom
:: ============================================================
:Search
cls
call "%_CORE%" :LogoHeader
echo ============================================================
echo    Recherche par nom
echo ============================================================
echo.
set "search="
set /p "search=   Chercher : "
if not defined search goto ChooseCat
echo.
echo    Resultats pour "!search!" :
echo.
set /a n=0
for /f "delims==" %%v in ('set found[ 2^>nul') do set "%%v="
for /f "delims=" %%F in ('dir /b /s /a-d "!ROOT!\*.bat" 2^>nul') do (
    set "fn=%%~nxF"
    set "skip="
    if /i "!fn!"=="Logiciels Utiles.bat" set "skip=1"
    if /i "!fn!"=="Installation par categorie.bat" set "skip=1"
    if not defined skip (
        echo !fn! | findstr /i "!search!" >nul
        if !errorlevel! equ 0 (
            set /a n+=1
            set "found[!n!]=%%~fF"
            echo    [!n!] !fn!
        )
    )
)
echo.
if !n! equ 0 (
    echo    Aucun logiciel trouve.
    echo.
    pause
    goto ChooseCat
)
echo    !n! resultat^(s^) : choisis un numero, une liste (1,3,5) ou 0.
echo.
set "c="
set /p "c=   Ton choix : "
if not defined c goto ChooseCat
if /i "!c!"=="0" goto ChooseCat
for %%P in (!c!) do call :Install "!found[%%P]!"
echo.
pause
goto ChooseCat


:: ============================================================
::  :Install <fichier.bat> - installe selon le type de commande
::  - winget  : execute la commande d'installation
::  - choco   : installe Chocolatey si besoin puis execute
::  - http    : ouvre la page de telechargement dans le navigateur
::  - custom  : installation manuelle (script dedie)
::  - aucune  : script special, ignore avec un message
:: ============================================================
:Install
setlocal EnableExtensions EnableDelayedExpansion
set "file=%~f1"
set "Logiciel="
set "cmdInstall="
set "cmdUpdate="
set "hasDownload="
for /f "usebackq tokens=1* delims==" %%A in ("!file!") do (
    set "k=%%A"
    set "k=!k:"=!"
    set "k=!k:set =!"
    set "v=%%B"
    set "v=!v:"=!"
    if /i "!k!"=="Logiciel" set "Logiciel=!v!"
    if /i "!k!"=="Install"  set "cmdInstall=!v!"
    if /i "!k!"=="Update"   set "cmdUpdate=!v!"
    if /i "!k!"=="Download" set "hasDownload=1"
)
if not defined Logiciel set "Logiciel=%~n1"

:: Classer la commande d'installation
set "type=none"
if defined cmdInstall (
    set "type=manual"
    set "probe=!cmdInstall!"
    if /i "!probe:~0,6!"=="winget" set "type=winget"
    if /i "!probe:~0,4!"=="http"   set "type=url"
    echo !probe! | findstr /i /c:"choco" >nul && set "type=choco"
)

echo.
echo    ==^> !Logiciel!

if /i "!type!"=="none" (
    if defined cmdUpdate (
        echo        Pas d'installation automatique ^(mise a jour winget seulement^).
    ) else if defined hasDownload (
        echo        Telechargement personnalise : installation manuelle requise.
    ) else (
        echo        Script special sans commande automatique : a lancer manuellement.
    )
    call "%_CORE%" :Log "!Logiciel!" "IGNORE" "aucune commande automatique"
    endlocal & exit /b
)

if /i "!type!"=="manual" (
    echo        Installation manuelle requise : lancez le script dedie.
    call "%_CORE%" :Log "!Logiciel!" "IGNORE" "installation manuelle"
    endlocal & exit /b
)

if /i "!type!"=="url" (
    echo        Ouverture de la page de telechargement...
    start "" "!cmdInstall!"
    call "%_CORE%" :Log "!Logiciel!" "URL" "page de telechargement"
    endlocal & exit /b
)

:: type == choco : garantir Chocolatey
if /i "!type!"=="choco" call :EnsureChoco

:: Execution (winget ou choco)
!cmdInstall!
set "rc=!errorlevel!"
if !rc! neq 0 (
    echo        [ECHEC] code !rc!
    call "%_CORE%" :Log "!Logiciel!" "ECHEC" "code !rc!"
) else (
    echo        [OK]
    call "%_CORE%" :Log "!Logiciel!" "OK" "installe"
)
endlocal & exit /b


:: ============================================================
::  :EnsureChoco - installe Chocolatey si absent
::  (subroutine a part : la commande powershell contient des
::   parentheses qui casseraient un bloc "if ( ... )")
:: ============================================================
:EnsureChoco
where choco.exe >nul 2>&1
if %errorlevel% equ 0 exit /b 0
echo        Installation de Chocolatey ^(pre-requis^)...
chcp 850 >nul
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))"
set "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"
chcp 65001 >nul
exit /b 0


:Quit
endlocal
exit /b 0
