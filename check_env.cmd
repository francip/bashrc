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
echo Looking for %COLOR_CYAN%common%COLOR_NONE% tools...

:: List of tools that output version to stderr
set STDERR_TOOLS=python python3 pip pip3

for %%t in (git gh brew bun nvm node npm yarn python python3 pip pip3 pipx poetry flutter dart go ruby gem arduino-cli) do (
    set "CMD_PATH="
    set "FOUND=0"

    where %%t.cmd >nul 2>&1 && (
        for /f "tokens=* delims=" %%p in ('where %%t.cmd 2^>nul') do if not defined CMD_PATH (
            echo %%p | findstr /i "WindowsApps" >nul || (
                set "CMD_PATH=%%p"
                set "FOUND=1"
                set "IS_SCRIPT=1"
            )
        )
    )

    if !FOUND! equ 0 (
        where %%t.bat >nul 2>&1 && (
            for /f "tokens=* delims=" %%p in ('where %%t.bat 2^>nul') do if not defined CMD_PATH (
                echo %%p | findstr /i "WindowsApps" >nul || (
                    set "CMD_PATH=%%p"
                    set "FOUND=1"
                    set "IS_SCRIPT=1"
                )
            )
        )
    )

    if !FOUND! equ 0 (
        where %%t.exe >nul 2>&1 && (
            for /f "tokens=* delims=" %%p in ('where %%t.exe 2^>nul') do if not defined CMD_PATH (
                echo %%p | findstr /i "WindowsApps" >nul || (
                    set "CMD_PATH=%%p"
                    set "FOUND=1"
                    set "IS_SCRIPT=0"
                )
            )
        )
    )

    if !FOUND! equ 0 (
        where %%t >nul 2>&1 && (
            for /f "tokens=* delims=" %%p in ('where %%t 2^>nul') do if not defined CMD_PATH (
                echo %%p | findstr /i "WindowsApps" >nul || (
                    set "CMD_PATH=%%p"
                    set "FOUND=1"
                    set "IS_SCRIPT=0"
                )
            )
        )
    )

    if !FOUND! equ 1 (
        echo.
        echo %COLOR_GREEN_BOLD%%%t%COLOR_NONE%

        set "VERSION_OUTPUT="
        echo !STDERR_TOOLS! | findstr /i "\<%%t\>" >nul && (
            :: Tool outputs version to stderr (like python and pip)
            for /f "usebackq tokens=*" %%v in (`"!CMD_PATH!" --version 2^>^&1`) do (
                set "VERSION_OUTPUT=%%v"
            )
        ) || (
            :: Normal version output handling
            if !IS_SCRIPT! equ 1 (
                call "!CMD_PATH!" --version >nul 2>&1 && (
                    for /f "usebackq tokens=*" %%v in (`call "!CMD_PATH!" --version 2^>nul`) do (
                        if defined VERSION_OUTPUT (
                            set "VERSION_OUTPUT=!VERSION_OUTPUT! %%v"
                        ) else (
                            set "VERSION_OUTPUT=%%v"
                        )
                    )
                ) || (
                    call "!CMD_PATH!" version >nul 2>&1 && (
                        for /f "usebackq tokens=*" %%v in (`call "!CMD_PATH!" version 2^>nul`) do (
                            if defined VERSION_OUTPUT (
                                set "VERSION_OUTPUT=!VERSION_OUTPUT! %%v"
                            ) else (
                                set "VERSION_OUTPUT=%%v"
                            )
                        )
                    )
                )
            ) else (
                "!CMD_PATH!" --version >nul 2>&1 && (
                    for /f "usebackq tokens=*" %%v in (`"!CMD_PATH!" --version 2^>nul`) do (
                        if defined VERSION_OUTPUT (
                            set "VERSION_OUTPUT=!VERSION_OUTPUT! %%v"
                        ) else (
                            set "VERSION_OUTPUT=%%v"
                        )
                    )
                ) || (
                    "!CMD_PATH!" version >nul 2>&1 && (
                        for /f "usebackq tokens=*" %%v in (`"!CMD_PATH!" version 2^>nul`) do (
                            if defined VERSION_OUTPUT (
                                set "VERSION_OUTPUT=!VERSION_OUTPUT! %%v"
                            ) else (
                                set "VERSION_OUTPUT=%%v"
                            )
                        )
                    )
                )
            )
        )
        if defined VERSION_OUTPUT echo %COLOR_CYAN_BOLD%  Version  : %COLOR_NONE%!VERSION_OUTPUT!

        echo %COLOR_CYAN_BOLD%  Location : %COLOR_NONE%!CMD_PATH!
    ) else (
        echo.
        echo %COLOR_RED_BOLD%%%t%COLOR_NONE%
        echo %COLOR_RED_BOLD%  Not found%COLOR_NONE%
    )
)

endlocal