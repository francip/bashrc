@echo off
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

echo.
echo Setting up %COLOR_CYAN_BOLD%Windows%COLOR_NONE% dev environment...
echo %COLOR_YELLOW%(some installers may prompt for elevation)%COLOR_NONE%

:: --- Directories ---

if not exist "C:\src" (
    echo.
    echo Creating %COLOR_CYAN_BOLD%C:\src%COLOR_NONE%
    mkdir "C:\src"
)

if not exist "C:\Tools" (
    echo.
    echo Creating %COLOR_CYAN_BOLD%C:\Tools%COLOR_NONE%
    mkdir "C:\Tools"
)

if not exist "C:\Tools\bin" (
    echo.
    echo Creating %COLOR_CYAN_BOLD%C:\Tools\bin%COLOR_NONE%
    mkdir "C:\Tools\bin"
)

:: Add C:\Tools\bin to user PATH if missing
set "USER_PATH="
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "USER_PATH=%%b"
echo !USER_PATH! | findstr /i /c:"C:\Tools\bin" >nul
if !errorlevel! neq 0 (
    echo.
    echo Adding %COLOR_CYAN_BOLD%C:\Tools\bin%COLOR_NONE% to user PATH
    powershell -NoProfile -Command "[Environment]::SetEnvironmentVariable('Path', [Environment]::GetEnvironmentVariable('Path','User') + ';C:\Tools\bin', 'User')" >nul
)

:: Pull current registry PATH into this session so newly installed tools become
:: visible to later steps without restarting the shell.
call :refresh_path

:: --- Package managers / version managers (everything else depends on these) ---

call :install_via_winget fnm     Schniz.fnm
call :install_via_winget python  Python.Python.3.13
call :install_via_ps     uv      https://astral.sh/uv/install.ps1

:: --- Core tools ---

call :install_via_winget git     Git.Git
call :install_via_winget gh      GitHub.cli
call :install_via_winget code    Microsoft.VisualStudioCode
call :install_via_winget copilot GitHub.Copilot
call :install_via_ps     bun     https://bun.sh/install.ps1

:: --- Languages ---

call :install_via_winget go      GoLang.Go
:: rustup provides rustc + cargo (run "rustup default stable" after install)
call :install_via_winget rustc   Rustlang.Rustup
:: ruby installer provides gem
call :install_via_winget ruby    RubyInstallerTeam.Ruby.3.4

:: --- Hardware tools ---

call :install_via_winget arduino-cli ArduinoSA.CLI

:: --- Node ecosystem (depends on fnm) ---

call :install_node
call :install_via_npm pnpm   pnpm
call :install_via_npm codex  @openai/codex

:: --- Python ecosystem (depends on python) ---

call :install_pipx
call :install_via_pipx poetry poetry

:: --- Tools we don't install on native Windows ---

echo.
echo %COLOR_YELLOW_BOLD%brew%COLOR_NONE% — not applicable on native Windows (use WSL if needed)
echo %COLOR_YELLOW_BOLD%nvm%COLOR_NONE%  — using fnm instead on Windows

echo.
echo --- %COLOR_CYAN_BOLD%Next steps%COLOR_NONE% ---
echo   Restart your shell so all PATH changes take effect
echo   gh auth login                          # Authenticate GitHub CLI
echo   rustup default stable                  # Install default Rust toolchain
echo   git config --global user.name "..."    # Set Git identity
echo   git config --global user.email "..."

endlocal
exit /b

:: ============================================================
:: Helpers
:: ============================================================

:check_tool
:: %1 = tool name. Sets HAS_TOOL=1 if installed (excluding WindowsApps stubs), else 0.
set "HAS_TOOL=0"
for /f "tokens=* delims=" %%p in ('where %~1 2^>nul') do (
    echo %%p | findstr /i "WindowsApps" >nul || set "HAS_TOOL=1"
)
goto :eof

:install_via_winget
:: %1 = tool name (for "where" check), %2 = winget package id
call :check_tool %~1
if !HAS_TOOL! equ 1 goto :eof
echo.
echo Installing %COLOR_GREEN_BOLD%%~1%COLOR_NONE%
winget install --id=%~2 -e --silent --accept-source-agreements --accept-package-agreements
call :refresh_path
goto :eof

:install_via_ps
:: %1 = tool name, %2 = installer script URL
call :check_tool %~1
if !HAS_TOOL! equ 1 goto :eof
echo.
echo Installing %COLOR_GREEN_BOLD%%~1%COLOR_NONE%
powershell -NoProfile -ExecutionPolicy Bypass -Command "irm %~2 | iex"
call :refresh_path
goto :eof

:install_node
:: Installs node via fnm; fnm.exe is in WinGet\Links so we reference it directly
:: in case fnm isn't on PATH yet.
call :check_tool node
if !HAS_TOOL! equ 1 goto :eof
set "FNM_EXE="
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Links\fnm.exe" set "FNM_EXE=%LOCALAPPDATA%\Microsoft\WinGet\Links\fnm.exe"
if not defined FNM_EXE (
    for /f "tokens=* delims=" %%p in ('where fnm 2^>nul') do if not defined FNM_EXE set "FNM_EXE=%%p"
)
if not defined FNM_EXE (
    echo.
    echo %COLOR_RED_BOLD%fnm not found - skipping node install%COLOR_NONE%
    goto :eof
)
echo.
echo Installing %COLOR_GREEN_BOLD%node%COLOR_NONE% via fnm
"!FNM_EXE!" install --lts
:: Wire up fnm's node/npm into this shell so downstream npm-based installs work
for /f "tokens=*" %%z in ('"!FNM_EXE!" env --use-on-cd') do call %%z
goto :eof

:install_via_npm
:: %1 = tool name (for "where" check), %2 = npm package name
call :check_tool %~1
if !HAS_TOOL! equ 1 goto :eof
call :check_tool npm
if !HAS_TOOL! neq 1 (
    echo.
    echo %COLOR_RED_BOLD%npm not found - skipping %~1 install%COLOR_NONE%
    goto :eof
)
echo.
echo Installing %COLOR_GREEN_BOLD%%~1%COLOR_NONE% via npm
call npm install -g %~2
goto :eof

:install_pipx
call :check_tool pipx
if !HAS_TOOL! equ 1 goto :eof
call :check_tool py
if !HAS_TOOL! neq 1 (
    echo.
    echo %COLOR_RED_BOLD%py launcher not found - skipping pipx install%COLOR_NONE%
    goto :eof
)
echo.
echo Installing %COLOR_GREEN_BOLD%pipx%COLOR_NONE% via pip
py -m pip install --user pipx
py -m pipx ensurepath
call :refresh_path
goto :eof

:install_via_pipx
:: %1 = tool name (for "where" check), %2 = pipx package name
call :check_tool %~1
if !HAS_TOOL! equ 1 goto :eof
call :check_tool pipx
if !HAS_TOOL! neq 1 (
    echo.
    echo %COLOR_RED_BOLD%pipx not found - skipping %~1 install%COLOR_NONE%
    goto :eof
)
echo.
echo Installing %COLOR_GREEN_BOLD%%~1%COLOR_NONE% via pipx
call pipx install %~2
goto :eof

:refresh_path
:: Reload PATH from registry (HKLM + HKCU) into the current session so installs
:: from this script become visible immediately.
set "MPATH="
set "UPATH="
for /f "tokens=2,*" %%a in ('reg query "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Environment" /v Path 2^>nul') do set "MPATH=%%b"
for /f "tokens=2,*" %%a in ('reg query "HKCU\Environment" /v Path 2^>nul') do set "UPATH=%%b"
if defined UPATH (
    set "PATH=!MPATH!;!UPATH!"
) else (
    set "PATH=!MPATH!"
)
goto :eof
