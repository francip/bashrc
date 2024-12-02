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

set "TARGET_DIR=C:\Tools\bin"

:: Create directories if they don't exist
if not exist "C:\Tools" mkdir "C:\Tools"
if not exist "C:\Tools\bin" mkdir "C:\Tools\bin"

:: List of scripts to symlink (only user-callable scripts)
set "SCRIPTS=check_env.cmd shrc.cmd"

:: Loop through each script
for %%s in (%SCRIPTS%) do (
    set "SOURCE_FILE=%SCRIPT_DIR%\%%s"
    set "SOURCE_FILE=!SOURCE_FILE:\\=\!"
    set "TARGET_FILE=%TARGET_DIR%\%%s"

    if not exist "!SOURCE_FILE!" (
        echo %COLOR_RED_BOLD%!TARGET_FILE!%COLOR_NONE%: Cannot be linked to non-existing %COLOR_RED_BOLD%!SOURCE_FILE!%COLOR_NONE%
    ) else if exist "!TARGET_FILE!" (
        fsutil reparsepoint query "!TARGET_FILE!" >nul 2>&1
        if !errorlevel! equ 0 (
            :: It's a symlink, check if it points to our file
            for /f "tokens=*" %%l in ('dir /al "!TARGET_FILE!" ^| find "["') do (
                set "LINK_TARGET=%%l"
            )
            set "LINK_TARGET=!LINK_TARGET:*[=!"
            set "LINK_TARGET=!LINK_TARGET:]=!"
            set "LINK_TARGET=!LINK_TARGET:\\=\!"

            if "!LINK_TARGET!"=="!SOURCE_FILE!" (
                echo %COLOR_GREEN_BOLD%!TARGET_FILE!%COLOR_NONE%: Already linked and points to %COLOR_CYAN_BOLD%!SOURCE_FILE!%COLOR_NONE%
            ) else (
                echo %COLOR_YELLOW_BOLD%!TARGET_FILE!%COLOR_NONE%: Already linked but points to %COLOR_YELLOW_BOLD%!LINK_TARGET!%COLOR_NONE% instead of %COLOR_CYAN_BOLD%!SOURCE_FILE!%COLOR_NONE%
            )
        ) else (
            echo %COLOR_YELLOW_BOLD%!TARGET_FILE!%COLOR_NONE%: Exists and cannot be linked to %COLOR_CYAN_BOLD%!SOURCE_FILE!%COLOR_NONE%
        )
    ) else (
        mklink "!TARGET_FILE!" "!SOURCE_FILE!" >nul
        if !errorlevel! equ 0 (
            echo %COLOR_GREEN_BOLD%!TARGET_FILE!%COLOR_NONE%: Created as a symbolic link and points to %COLOR_CYAN_BOLD%!SOURCE_FILE!%COLOR_NONE%
        ) else (
            echo %COLOR_RED_BOLD%!TARGET_FILE!%COLOR_NONE%: Failed to create symbolic link
        )
    )
)

:: Handle AutoRun registry key
set "REG_KEY=HKCU\Software\Microsoft\Command Processor"
set "REG_VALUE=AutoRun"
set "TARGET_PATH=%TARGET_DIR%\shrc.cmd"

:: Check if AutoRun exists and get its value
reg query "%REG_KEY%" /v "%REG_VALUE%" >nul 2>&1
if !errorlevel! equ 0 (
    :: Key exists, get its value
    for /f "tokens=2,*" %%a in ('reg query "%REG_KEY%" /v "%REG_VALUE%" ^| findstr /i "AutoRun"') do (
        set "CURRENT_VALUE=%%b"
    )

    if "!CURRENT_VALUE!"=="!TARGET_PATH!" (
        echo %COLOR_GREEN_BOLD%AutoRun%COLOR_NONE%: Already configured to use %COLOR_CYAN_BOLD%!TARGET_PATH!%COLOR_NONE%
    ) else (
        echo %COLOR_YELLOW_BOLD%AutoRun%COLOR_NONE%: Currently points to %COLOR_YELLOW_BOLD%!CURRENT_VALUE!%COLOR_NONE% instead of %COLOR_CYAN_BOLD%!TARGET_PATH!%COLOR_NONE%
    )
) else (
    :: Key doesn't exist, create it
    reg add "%REG_KEY%" /v "%REG_VALUE%" /t REG_SZ /d "%TARGET_PATH%" /f >nul
    if !errorlevel! equ 0 (
        echo %COLOR_GREEN_BOLD%AutoRun%COLOR_NONE%: Successfully configured to use %COLOR_CYAN_BOLD%!TARGET_PATH!%COLOR_NONE%
    ) else (
        echo %COLOR_RED_BOLD%AutoRun%COLOR_NONE%: Failed to add registry key
    )
)

endlocal