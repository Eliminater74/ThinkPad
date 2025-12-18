@echo off
TITLE ThinkPad Debloater Launcher
CLS

ECHO ========================================================
ECHO Checking for Administrator privileges...
ECHO ========================================================

:: Check for Administrative permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

:: If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo.
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    echo UAC.ShellExecute "%~s0", "", "", "runas", 1 >> "%temp%\getadmin.vbs"
    "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    if exist "%temp%\getadmin.vbs" ( del "%temp%\getadmin.vbs" )
    pushd "%CD%"
    CD /D "%~dp0"
    
    ECHO.
    ECHO Launching ThinkPad Debloater...
    ECHO.
    
    :: Launch PowerShell with Bypass policy
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "ThinkPadDebloater.ps1"
    
    ECHO.
    ECHO Script finished.
    PAUSE
