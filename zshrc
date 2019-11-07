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
    # TODO: Determine if interactive shell

    if [[ -d $HOME/.oh-my-zsh ]]; then
        export ZSH="$HOME/.oh-my-zsh"

        ZSH_THEME="amuse"
        COMPLETION_WAITING_DOTS="true"
        DISABLE_UNTRACKED_FILES_DIRTY="true"
        HIST_STAMPS="yyyy-mm-dd"

        plugins=(git mercurial)

        source $ZSH/oh-my-zsh.sh
    fi

    # setopt AUTO_CD
    # setopt AUTO_PUSHD
    # setopt AUTO_NAME_DIRS
    # setopt GLOB_COMPLETE
    # setopt PUSHD_MINUS
    # setopt PUSHD_SILENT
    # setopt PUSHD_TO_HOME

    # bindkey '\e[1~' beginning-of-line
    # bindkey '\e[4~' end-of-line

    # TODO: Add personal key to ssh agent

    # export PS1='%% '

    env
}

__zshrc_main "$@"
unset __zshrc_main
