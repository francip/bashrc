#!/usr/bin/env bash

# This file is not intended for direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then exit; fi

if [[ -f "$HOME/.bashrc" ]]; then
    . "$HOME/.bashrc"
fi

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
