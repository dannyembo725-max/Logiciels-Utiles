@echo off
chcp 65001 >nul
setlocal EnableExtensions
CLS

:: =============
:: Config du script
:: =============

set "Logiciel=Dolby"

:: Vidéo Youtube
set "Presentation=https://youtu.be/o_oSOsT8ioM"

:: Site officiel / Github
set "Github=https://github.com/SimonMacer/AnWave/releases/tag/RollbackDolby"

:: Installation automatique
set "Install=winget.exe install --id 9N0866FS04W8 --exact --source msstore --accept-source-agreements --disable-interactivity --silent --accept-package-agreements --force"
:: Mise à jour automatique
set "Update=winget.exe upgrade --id 9N0866FS04W8 --exact --source msstore --accept-source-agreements --disable-interactivity --silent --accept-package-agreements"

:: ============
:: Fin de la config
:: ============


:: Vérifie si le script est exécuté en tant qu'administrateur
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Le script nécessite des droits administratifs.
    echo Redémarrage avec élévation de privilèges...
    powershell.exe -Command "Start-Process '%~0' -Verb RunAs"
    exit /b
)

:Menu
CLS

title %Logiciel% - Menu

echo Create by Mathys M - karde.me/mathysm
echo.
echo.
echo       ███╗   ███╗███████╗███╗   ██╗██╗   ██╗
echo       ████╗ ████║██╔════╝████╗  ██║██║   ██║
echo       ██╔████╔██║█████╗  ██╔██╗ ██║██║   ██║
echo       ██║╚██╔╝██║██╔══╝  ██║╚██╗██║██║   ██║
echo       ██║ ╚═╝ ██║███████╗██║ ╚████║╚██████╔╝
echo       ╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝
echo.
echo.

echo 1. Présentation
echo 2. Site officiel / Github
echo 3. Installation automatique
echo 4. Désinstallation
echo 5. Mettre à jour
echo.

CHOICE /C 12345 /M "Entre ton choix:"

IF ERRORLEVEL 5 GOTO Update
IF ERRORLEVEL 4 GOTO Uninstall
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
CLS

title %Logiciel% - Mise à jour

echo Create by Mathys M - karde.me/mathysm
echo.
echo.
echo       ██╗   ██╗██████╗ ██████╗  █████╗ ████████╗███████╗
echo       ██║   ██║██╔══██╗██╔══██╗██╔══██╗╚══██╔══╝██╔════╝
echo       ██║   ██║██████╔╝██║  ██║███████║   ██║   █████╗  
echo       ██║   ██║██╔═══╝ ██║  ██║██╔══██║   ██║   ██╔══╝  
echo       ╚██████╔╝██║     ██████╔╝██║  ██║   ██║   ███████╗
echo        ╚═════╝ ╚═╝     ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝
echo.
echo.

%Update%

echo.
echo.
echo Mise à jour terminée !
echo.
echo Retour au menu dans:
for /L %%i in (4,-1,1) do (
    echo %%i...
    timeout /t 1 /nobreak >nul
)

GOTO Menu


:Install
CLS

title %Logiciel% - Installation automatique

echo Create by Mathys M - karde.me/mathysm
echo.
echo.
echo       ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
echo       ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
echo       ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
echo       ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
echo       ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
echo       ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
echo.
echo.

chcp 850 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ProgressPreference='SilentlyContinue'; $u='https://github.com/SimonMacer/AnWave/releases/download/RollbackDolby/RollbackDolby-v1.2.0.81-20260626.rar'; $d=Join-Path $env:TEMP 'RollbackDolby-v1.2.0.81-20260626.rar'; $o=[Environment]::GetFolderPath('Desktop'); Invoke-WebRequest -UseBasicParsing -Uri $u -OutFile $d; tar.exe -xf $d -C $o; Remove-Item $d -Force; Start-Process (Join-Path $o 'RollbackDolby.exe')"
chcp 65001 >nul

%Install%

CLS

title %Logiciel% - Installation automatique

echo Create by Mathys M - https://www.karde.me/mathysm
echo.
echo.
echo       ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
echo       ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
echo       ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
echo       ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
echo       ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
echo       ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝
echo.
echo.

echo Installation terminée !
echo.
echo Le .exe a été placé sur le Bureau
echo.
pause
GOTO Menu

:Uninstall
CLS

title %Logiciel% - Installation automatique

echo Create by Mathys M - karde.me/mathysm
echo.
echo.
echo       ██╗   ██╗███╗   ██╗██╗███╗   ██╗███████╗████████╗ █████╗ ██╗     ██╗     
echo       ██║   ██║████╗  ██║██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██║     
echo       ██║   ██║██╔██╗ ██║██║██╔██╗ ██║███████╗   ██║   ███████║██║     ██║     
echo       ██║   ██║██║╚██╗██║██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██║     
echo       ╚██████╔╝██║ ╚████║██║██║ ╚████║███████║   ██║   ██║  ██║███████╗███████╗
echo        ╚═════╝ ╚═╝  ╚═══╝╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚══════╝                                                                      
echo.
echo.

dism /Online /Remove-Package /PackageName:Microsoft-Windows-DolbyCodec-WOW64-Package~31bf3856ad364e35~wow64~~10.0.26100.1

dism /Online /Remove-Package /PackageName:Microsoft-Windows-DolbyCodec-Package~31bf3856ad364e35~amd64~~10.0.26100.1

echo.
echo.
echo Désinstallation terminée !
echo.
echo Retour au menu dans:
for /L %%i in (4,-1,1) do (
    echo %%i...
    timeout /t 1 /nobreak >nul
)

GOTO Menu