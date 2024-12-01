@echo off
chcp 65001 >nul
setlocal EnableDelayedExpansion

:: Color definitions for Windows console
set "ESC="
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "ESC=%%b"
)

set "GREEN=%ESC%[92m"
set "CYAN=%ESC%[96m"
set "RED=%ESC%[91m"
set "YELLOW=%ESC%[93m"
set "RESET=%ESC%[0m"

echo.
echo Looking for %CYAN%common%RESET% tools...

:: List of tools that output version to stderr
set STDERR_TOOLS=python python3 pip pip3

for %%t in (git gh brew nvm node npm yarn python python3 pip pip3 pipx poetry flutter dart go ruby gem arduino-cli) do (
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
        echo %GREEN%%%t%RESET%

        if "%%t"=="nvm" (
            echo %CYAN%  Version  : %RESET%%YELLOW%...nvm is stupid and does not allow standard output redirection...%RESET%
        ) else (
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
            if defined VERSION_OUTPUT echo %CYAN%  Version  : %RESET%!VERSION_OUTPUT!
        )

        echo %CYAN%  Location : %RESET%!CMD_PATH!
    ) else (
        echo.
        echo %RED%%%t%RESET%
        echo %RED%  Not found%RESET%
    )
)

endlocal