@echo off
setlocal EnableDelayedExpansion

:: Color definitions for Windows console
set "GREEN=[32m"
set "CYAN=[36m"
set "RED=[31m"
set "BOLD=[1m"
set "RESET=[0m"

:: Function to check commands
:get_commands_info
    for %%c in (%*) do (
        where %%c >nul 2>&1
        if !errorlevel! equ 0 (
            echo.
            echo !GREEN!!BOLD!%%c!RESET!

            :: Try to get version
            %%c --version >nul 2>&1
            if !errorlevel! equ 0 (
                for /f "tokens=*" %%v in ('%%c --version 2^>nul') do (
                    echo !CYAN!!BOLD!  Version  : !RESET!%%v
                    goto :version_done_%%c
                )
            )
            %%c version >nul 2>&1
            if !errorlevel! equ 0 (
                for /f "tokens=*" %%v in ('%%c version 2^>nul') do (
                    echo !CYAN!!BOLD!  Version  : !RESET!%%v
                    goto :version_done_%%c
                )
            )
            :version_done_%%c

            :: Get location
            for /f "tokens=*" %%p in ('where %%c 2^>nul') do (
                echo !CYAN!!BOLD!  Location : !RESET!%%p
                goto :location_done_%%c
            )
            :location_done_%%c
        ) else (
            echo.
            echo !RED!!BOLD!%%c!RESET!
            echo !RED!!BOLD!  Not found!RESET!
        )
    )
    exit /b

:: Main script
echo.
echo Looking for !CYAN!!BOLD!common!RESET! tools...

call :get_commands_info git gh brew nvm node npm yarn python python3 pip pip3 pipx poetry flutter dart go ruby gem arduino-cli

endlocal
