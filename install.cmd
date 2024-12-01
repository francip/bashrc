@echo off
setlocal EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "TARGET_DIR=C:\Tools\bin"

if not exist "C:\Tools" mkdir "C:\Tools"
if not exist "C:\Tools\bin" mkdir "C:\Tools\bin"

set "SOURCE_FILE=%SCRIPT_DIR%\check_env.cmd"
set "TARGET_FILE=%TARGET_DIR%\check_env.cmd"

if exist "%TARGET_FILE%" (
    fsutil reparsepoint query "%TARGET_FILE%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo Link already exists at %TARGET_FILE%
    ) else (
        echo File already exists at %TARGET_FILE% and is not a symbolic link
    )
) else (
    mklink "%TARGET_FILE%" "%SOURCE_FILE%"
    if !errorlevel! equ 0 (
        echo Successfully created link at %TARGET_FILE%
    ) else (
        echo Failed to create link
    )
)

endlocal