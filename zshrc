#!/usr/bin/env zsh

# This file is not intended for direct execution
case $ZSH_EVAL_CONTEXT in
*file)
    ;;
*file:cmdsubst)
    ;;
*)
    exit
    ;;
esac

__zshrc_main() {
    setopt AUTO_CD
    setopt AUTO_PUSHD
    setopt AUTO_NAME_DIRS
    setopt GLOB_COMPLETE
    setopt PUSHD_MINUS
    setopt PUSHD_SILENT
    setopt PUSHD_TO_HOME

    bindkey '\e[1~' beginning-of-line
    bindkey '\e[4~' end-of-line

    export PS1='%% '
}

__zshrc_main "$@"
unset __zshrc_main
