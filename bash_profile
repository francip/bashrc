#!/bin/bash

# This file is not intended for direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then exit; fi

if [[ -f "$HOME/.bashrc" ]]; then
    . "$HOME/.bashrc"
fi
