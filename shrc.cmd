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
    doskey cld=claude --dangerously-skip-permissions --add-dir C:\Src $*

    REM Point Git and SSH at the Windows native OpenSSH so everything
    REM -- including Git Bash shells spawned by Claude Code -- uses the
    REM Windows ssh-agent service instead of a standalone Git Bash agent.
    if exist "C:\Windows\System32\OpenSSH\ssh.exe" (
        endlocal
        set "GIT_SSH=C:\Windows\System32\OpenSSH\ssh.exe"
        set "WIN_OPENSSH_DIR=C:\Windows\System32\OpenSSH"
        setlocal EnableDelayedExpansion
        echo.
        echo Configuring %COLOR_GREEN_BOLD%SSH%COLOR_NONE% to use Windows native %COLOR_GREEN_BOLD%OpenSSH%COLOR_NONE% + %COLOR_GREEN_BOLD%ssh-agent%COLOR_NONE%
    )

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