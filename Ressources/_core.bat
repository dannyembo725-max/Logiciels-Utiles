@echo off
:: ===================================================================
:: _core.bat - Bibliotheque partagee pour "Logiciels Utiles by Mathys M"
:: ===================================================================
:: Usage depuis un script :
::   set "Logiciel=Nom du Logiciel"
::   set "Install=winget.exe install ..."
::   set "Update=winget.exe upgrade ..."
::   set "_CORE=..\..\Ressources\_core.bat"
::
::   call "%_CORE%" :AdminCheck "%~f0"
::   call "%_CORE%" :LogoHeader
::   call "%_CORE%" :DoInstall
::   call "%_CORE%" :DoUpdate
::
:: IMPORTANT : cmd.exe n'accepte PAS "call fichier.bat :Label" comme un
:: saut direct. Il execute le fichier DEPUIS LE DEBUT et passe seulement
:: ":Label" dans %1. Sans le dispatch ci-dessous, tout appel retomberait
:: sur :AdminCheck et quitterait aussitot. On saute donc explicitement
:: vers le label demande.
:: ===================================================================

:: Chemins partages (relatifs a _core.bat)
set "_LOG_FILE=%~dp0install.log"
set "_PACK_ROOT=%~dp0.."

:: Dispatcher : va directement au label demande (%~1 == ":Label", etc.)
if not "%~1"=="" goto %~1

:: Aucun label demande -> aide
goto :Help


:: ─── :AdminCheck ─────────────────────────────────────────────────
:: Verifie les droits administrateur. Si absents, relance le SCRIPT
:: APPELANT en elevation. Le chemin de l'appelant doit etre passe en %2 :
::     call "%_CORE%" :AdminCheck "%~f0"
:AdminCheck
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Le script necessite des droits administratifs.
    echo Redemarrage avec elevation de privileges...
    if "%~2"=="" (
        echo [ERREUR] Chemin du script appelant introuvable.
        echo Appelez :AdminCheck avec le chemin du script en 2e argument.
        exit /b 1
    )
    powershell.exe -Command "Start-Process '%~2' -Verb RunAs"
    exit /b 1
)
exit /b 0


:: ─── :LogoHeader ─────────────────────────────────────────────────
:: Affiche la signature + banniere ASCII
:LogoHeader
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
exit /b 0


:: ─── :DoInstall ──────────────────────────────────────────────────
:: Execute %Install% avec gestion d'erreurs et journalisation.
:: Variables requises : %Install%, %Logiciel%
:DoInstall
CLS
title %Logiciel% - Installation automatique

call :LogoHeader

echo       Installation en cours...
echo.

%Install%
set "_INSTALL_RC=%errorlevel%"

if %_INSTALL_RC% neq 0 (
    call :Log "%Logiciel%" "ECHEC" "install code %_INSTALL_RC%"
    echo.
    echo [ERREUR] L'installation a echoue ^(code %_INSTALL_RC%^)
    echo Consultez install.log pour plus de details.
    echo.
    pause
    exit /b 1
)

call :Log "%Logiciel%" "OK" "installe"
echo.
echo Installation terminee avec succes !
call :Countdown
exit /b 0


:: ─── :DoUpdate ───────────────────────────────────────────────────
:: Execute %Update% avec gestion d'erreurs et journalisation.
:: Variables requises : %Update%, %Logiciel%
:DoUpdate
CLS
title %Logiciel% - Mise a jour

call :LogoHeader

echo       Mise a jour en cours...
echo.

%Update%
set "_UPDATE_RC=%errorlevel%"

if %_UPDATE_RC% neq 0 (
    call :Log "%Logiciel%" "ECHEC" "update code %_UPDATE_RC%"
    echo.
    echo [ERREUR] La mise a jour a echoue ^(code %_UPDATE_RC%^)
    echo Consultez install.log pour plus de details.
    echo.
    pause
    exit /b 1
)

call :Log "%Logiciel%" "OK" "mis a jour"
echo.
echo Mise a jour terminee avec succes !
call :Countdown
exit /b 0


:: ─── :Countdown ──────────────────────────────────────────────────
:: Compte a rebours 4 -> 1 avant retour au menu
:Countdown
echo.
echo Retour au menu dans:
for /L %%i in (4,-1,1) do (
    echo %%i...
    timeout /t 1 /nobreak >nul
)
exit /b 0


:: ─── :Log ────────────────────────────────────────────────────────
:: Ecrit une entree dans install.log.
:: Accepte un appel interne  : call :Log "Nom" "OK" "message"
:: ou un appel externe       : call _core.bat :Log "Nom" "OK" "message"
:: (dans ce cas %1 vaut ":Log" et on decale les arguments).
:Log
if /i "%~1"==":Log" shift
if not defined _LOG_FILE set "_LOG_FILE=%~dp0install.log"
if not exist "%_LOG_FILE%" (
    echo === install.log - cree le %date% %time% === > "%_LOG_FILE%"
)
echo [%date% %time%] %~1 : %~2 (%~3) >> "%_LOG_FILE%"
exit /b 0


:: ─── :Help ───────────────────────────────────────────────────────
:: Affiche quand _core.bat est lance sans label.
:Help
echo _core.bat - bibliotheque partagee
echo Usage : call "_core.bat" :AdminCheck "%%~f0"
echo         call "_core.bat" :LogoHeader
echo         call "_core.bat" :DoInstall
echo         call "_core.bat" :DoUpdate
echo         call "_core.bat" :Log "Nom" "STATUS" "message"
exit /b 1
