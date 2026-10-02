@echo off
chcp 65001 >nul
setlocal EnableExtensions
CLS

:: =============
:: Config du script
:: =============

set "Logiciel=VoiceMeeter"

:: Vidéo Youtube
set "Presentation=https://youtu.be/n1fOZkAx75Y"

:: Site officiel / Github
set "Github=https://vb-audio.com/Voicemeeter/potato.htm"

:: Installation automatique
set "Install=winget.exe install --id VB-Audio.Voicemeeter.Potato --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements --force"
:: Mise à jour automatique
set "Update=winget.exe upgrade --id VB-Audio.Voicemeeter.Potato --exact --source winget --accept-source-agreements --disable-interactivity --silent --accept-package-agreements"

:: ============
:: Fin de la config
:: ============


:: Bibliothèque partagée (_core.bat)
set "_CORE=%~dp0..\..\..\Ressources\_core.bat"

:: Vérification des droits administrateur
call "%_CORE%" :AdminCheck "%~f0"
if %errorlevel% neq 0 exit /b 1

:Menu
CLS

title %Logiciel% - Menu

call "%_CORE%" :LogoHeader

echo 1. Présentation
echo 2. Site officiel / Github
echo 3. Installation automatique
echo 4. Mettre à jour
echo.

CHOICE /C 1234 /M "Entre ton choix:"

IF ERRORLEVEL 4 GOTO Update
IF ERRORLEVEL 3 GOTO Install
IF ERRORLEVEL 2 GOTO Github
IF ERRORLEVEL 1 GOTO Presentation


:Presentation
CLS

start "" "%Presentation%"

GOTO Menu


:Github
CLS

start "" "%Github%"

GOTO Menu


:Update
call "%_CORE%" :DoUpdate
GOTO Menu


:Install
call "%_CORE%" :DoInstall
GOTO Menu

