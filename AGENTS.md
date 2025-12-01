# CLAUDE.md - Shell Environment Configuration Framework

## Commands
- **Install:** `./bash_install.sh` (Bash) or `./zsh_install.sh` (Zsh)
- **Test OS Detection:** `./os_test.sh`
- **Test Symlinks:** `./ln_test.sh`
- **Test Direct Execution:** `./direct_test.sh`
- **Uninstall:** `./bash_uninstall.sh` or `./zsh_uninstall.sh`

## Code Style Guidelines
- **Naming Conventions:**
  - Function names use double underscore prefix (`__function_name`)
  - Filenames use kebab-case (`file-name.sh`)
  - Variable names use UPPER_SNAKE_CASE for constants/configuration, lower_snake_case for locals
- **Function Style:**
  - Each script has a main function (`__script_main`) that is called at the end and unset afterward
  - Functions should be self-contained with local variables
- **Error Handling:** Use echo with color-coded output for warnings and errors
- **Cross-Platform:** Scripts should detect and adapt to different OS environments
- **Documentation:** Comment non-obvious code sections, especially OS-specific parts

## Platform Support
- Linux (various distros)
- macOS
- Windows WSL
- Windows cmd (as a parallel set of scripts)
