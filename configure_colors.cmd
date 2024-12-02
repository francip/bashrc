@echo off
:: Color definitions for Windows console

:: Initialize ESC sequence
set "ESC="
for /f "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do (
  set "ESC=%%b"
)

:: Regular colors
set "COLOR_RED=%ESC%[0;31m"
set "COLOR_GREEN=%ESC%[0;32m"
set "COLOR_YELLOW=%ESC%[0;33m"
set "COLOR_BLUE=%ESC%[0;34m"
set "COLOR_MAGENTA=%ESC%[0;35m"
set "COLOR_CYAN=%ESC%[0;36m"
set "COLOR_WHITE=%ESC%[0;37m"
set "COLOR_NONE=%ESC%[0m"

:: Bold/bright colors
set "COLOR_RED_BOLD=%ESC%[1;31m"
set "COLOR_GREEN_BOLD=%ESC%[1;32m"
set "COLOR_YELLOW_BOLD=%ESC%[1;33m"
set "COLOR_BLUE_BOLD=%ESC%[1;34m"
set "COLOR_MAGENTA_BOLD=%ESC%[1;35m"
set "COLOR_CYAN_BOLD=%ESC%[1;36m"
set "COLOR_WHITE_BOLD=%ESC%[1;37m"
set "COLOR_BOLD=%ESC%[1m"

:: Underline colors
set "COLOR_RED_UNDERLINE=%ESC%[4;31m"
set "COLOR_GREEN_UNDERLINE=%ESC%[4;32m"
set "COLOR_YELLOW_UNDERLINE=%ESC%[4;33m"
set "COLOR_BLUE_UNDERLINE=%ESC%[4;34m"
set "COLOR_MAGENTA_UNDERLINE=%ESC%[4;35m"
set "COLOR_CYAN_UNDERLINE=%ESC%[4;36m"
set "COLOR_WHITE_UNDERLINE=%ESC%[4;37m"
set "COLOR_UNDERLINE=%ESC%[4m"

:: Inverted colors
set "COLOR_RED_INVERT=%ESC%[7;31m"
set "COLOR_GREEN_INVERT=%ESC%[7;32m"
set "COLOR_YELLOW_INVERT=%ESC%[7;33m"
set "COLOR_BLUE_INVERT=%ESC%[7;34m"
set "COLOR_MAGENTA_INVERT=%ESC%[7;35m"
set "COLOR_CYAN_INVERT=%ESC%[7;36m"
set "COLOR_WHITE_INVERT=%ESC%[7;37m"
set "COLOR_INVERT=%ESC%[7m"

:: Return control to calling script
goto :eof