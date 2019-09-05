#!/usr/bin/env zsh

# This file is not intended for direct execution
if [[ "${ZSH_SOURCE[0]}" == "$0" ]]; then exit; fi

# Source common definitions

__zshrc_main() {
}

__zshrc_main "$@"
unset __zshrc_main
