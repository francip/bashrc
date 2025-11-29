@echo off
if defined SHRC_RUNNING exit /b
set "SHRC_RUNNING=1"

setlocal EnableDelayedExpansion
chcp 65001 >nul

:: Get script directory (resolving symlinks)
set "SCRIPT_PATH=%~f0"
fsutil reparsepoint query "%SCRIPT_PATH%" >nul 2>&1
if !errorlevel! equ 0 (
    :: It's a symlink, get the target
    for /f "tokens=*" %%l in ('dir /al "%SCRIPT_PATH%" ^| find "["') do (
        set "LINK_TARGET=%%l"
    )
    set "LINK_TARGET=!LINK_TARGET:*[=!"
    set "LINK_TARGET=!LINK_TARGET:]=!"
    for %%i in ("!LINK_TARGET!") do set "SCRIPT_DIR=%%~dpi"
    set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
) else (
    :: Not a symlink, use the direct path
    set "SCRIPT_DIR=%~dp0"
    set "SCRIPT_DIR=!SCRIPT_DIR:~0,-1!"
)

call "!SCRIPT_DIR!\configure_colors.cmd"

:: Check if running in interactive mode
set "IS_INTERACTIVE=0"
echo %CMDCMDLINE% | findstr /i /c:"/c" >nul
if errorlevel 1 (
    echo %CMDCMDLINE% | findstr /i /c:"/k" >nul
    if errorlevel 0 set "IS_INTERACTIVE=1"
) else (
    set "IS_INTERACTIVE=0"
)

echo.

if !IS_INTERACTIVE! equ 1 (
    echo Configuring environment for %COLOR_GREEN_BOLD%cmd%COLOR_NONE% on %COLOR_GREEN_BOLD%Windows%COLOR_NONE%

    doskey ls=dir $*
    doskey cat=type $*
    doskey e=agy $*

    :: for /F will launch a new instance of cmd so we create a guard to prevent an infnite loop
    if not defined FNM_AUTORUN_GUARD (
        echo.
        echo Configuring %COLOR_GREEN_BOLD%node.js%COLOR_NONE%
        endlocal
        set "FNM_AUTORUN_GUARD=AutorunGuard"
        for /f "tokens=*" %%z in ('fnm env --use-on-cd') do (
            call %%z
        )
        setlocal EnableDelayedExpansion
    )
)

setlocal DisableDelayedExpansion
endlocal
set "SHRC_RUNNING="