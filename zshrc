# Source common definitions

__zshrc_main() {
    local SH_SOURCE_FILE SH_SOURCE_DIR SH_SOURCE_FILE_ESCAPED

    if [ -n "$ZSH_VERSION" ]; then
        SH_SOURCE_FILE=${(%):-%x}
    elif [ -n "$BASH_VERSION" ]; then
        SH_SOURCE_FILE=${BASH_SOURCE[0]}
    fi

    while [[ -L "$SH_SOURCE_FILE" ]]; do
        SH_SOURCE_FILE=$(readlink "$SH_SOURCE_FILE")
    done

    SH_SOURCE_DIR=$(dirname "$SH_SOURCE_FILE")
    SH_SOURCE_DIR=`cd "$SH_SOURCE_DIR" >/dev/null; pwd`
    SH_SOURCE_FILE=$(basename "$SH_SOURCE_FILE")
    SH_SOURCE_FILE_ESCAPED=${SH_SOURCE_FILE// /_}

    # SH_SOURCE_DIR is a full path to the location of this script

    eval "$(cat <<EOF
        __get_${SH_SOURCE_FILE_ESCAPED}_dir() {
          echo $SH_SOURCE_DIR
        }
        __get_${SH_SOURCE_FILE_ESCAPED}_file() {
          echo $SH_SOURCE_FILE
        }
        __get_sh_scripts_dir() {
          echo "$SH_SOURCE_DIR"
        }
        __get_sh_scripts_file() {
          echo "$SH_SOURCE_FILE"
        }
EOF
)"

    local SH_COLOR_DEFS
    if [[ -e "$SH_SOURCE_DIR/configure_colors" ]]; then
        SH_COLOR_DEFS=`cat "$SH_SOURCE_DIR/configure_colors"`
    fi

    local SH_OS_DEFS
    if [[ -e "$SH_SOURCE_DIR/configure_os" ]]; then
        SH_OS_DEFS=`cat "$SH_SOURCE_DIR/configure_os"`
    fi

    eval "$(cat <<EOF
        __sh_color_definitions() {
            echo "$SH_COLOR_DEFS"
        }
        __sh_os_definitions() {
            echo "$SH_OS_DEFS"
        }
EOF
)"

    eval "$(__sh_color_definitions)"
    eval "$(__sh_os_definitions)"

    local SH_INTERACTIVE

    case $- in
    *i*)
        # interactive shell
        SH_INTERACTIVE=1
        ;;
    esac

    . "${SH_SOURCE_DIR}/shrc_helpers"

    [[ $SH_INTERACTIVE ]] && echo
    [[ $SH_INTERACTIVE ]] && echo -e 'Configuring environment for '$COLOR_GREEN_BOLD'Zsh '${ZSH_VERSION}$COLOR_NONE' on '$COLOR_GREEN_BOLD$SH_OS_DISTRO$COLOR_NONE' '$COLOR_GREEN_BOLD$SH_OS_RELEASE$COLOR_NONE' ('$COLOR_GREEN_BOLD$SH_OS_TYPE$COLOR_NONE')'

    if [[ $SH_OS_TYPE == Windows ]]; then
        export SSH_AUTH_SOCK=/tmp/.ssh-socket
        ssh-add -l >/dev/null 2>&1
        if [[ $? = 2 ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Creating new ssh-agent'
            rm -f /tmp/.ssh-script /tmp/.ssh-agent-pid /tmp/.ssh-socket
            ssh-agent -a $SSH_AUTH_SOCK > /tmp/.ssh-script
            . /tmp/.ssh-script
            [[ $SH_INTERACTIVE ]] && echo $SSH_AGENT_PID > /tmp/.ssh-agent-pid
        fi
    fi

    if [[ $SH_OS_TYPE == Linux ]]; then
        if [[ -z "$(pgrep ssh-agent)" ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'SSH agent '$COLOR_YELLOW_BOLD'not running'$COLOR_NONE'. Starting new one...'
            rm -rf /tmp/ssh-* 2>/dev/null
            eval $(ssh-agent -s) >/dev/null
        else
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'SSH agent '$COLOR_GREEN_BOLD'running'$COLOR_NONE'. Connecting...'
            export SSH_AGENT_PID=$(pgrep ssh-agent)
            export SSH_AUTH_SOCK=$(find /tmp/ssh-* -name agent.\* 2>/dev/null)
        fi
    fi

    ssh-add >/dev/null 2>&1

    if [[ -f "${HOME}/.ssh/id_rsa_personal" ]]; then
        if [[ `ssh-add -l | grep -i id_rsa_personal | wc -l` -lt 1 ]]; then
            if [[ $SH_OS_TYPE == OSX ]]; then
                ssh-add -K ${HOME}/.ssh/id_rsa_personal >/dev/null 2>&1
            else
                ssh-add ${HOME}/.ssh/id_rsa_personal >/dev/null 2>&1
            fi
        fi
    fi

    # Source additional global, local, and personal definitions
    [[ $SH_INTERACTIVE ]] && echo
    __include_files "${HOME}/.zshrc_local" "${SH_SOURCE_DIR}/aliases" "${HOME}/.aliases_local"

    # Set up the prompt
    autoload -Uz promptinit
    promptinit
    prompt adam1

    setopt histignorealldups sharehistory

    # Keep 1000 lines of history within the shell and save it to ~/.zsh_history:
    HISTSIZE=1000
    SAVEHIST=1000
    HISTFILE=~/.zsh_history

    # Use modern completion system
    autoload -Uz compinit
    compinit

    zstyle ':completion:*' auto-description 'specify: %d'
    zstyle ':completion:*' completer _expand _complete _correct _approximate
    zstyle ':completion:*' format 'Completing %d'
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*' menu select=2
    eval "$(dircolors -b)"
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
    zstyle ':completion:*' list-colors ''
    zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
    zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
    zstyle ':completion:*' menu select=long
    zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
    zstyle ':completion:*' use-compctl false
    zstyle ':completion:*' verbose true

    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
    zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

    if [[ -d $HOME/.oh-my-zsh ]]; then
        export ZSH="$HOME/.oh-my-zsh"

        ZSH_THEME="amuse"
        COMPLETION_WAITING_DOTS="true"
        DISABLE_UNTRACKED_FILES_DIRTY="true"
        HIST_STAMPS="yyyy-mm-dd"

        plugins=(git mercurial)

        source $ZSH/oh-my-zsh.sh
    fi

    local PATH_DIRS=( "${HOME}/bin" )
    if [[ $SH_OS_TYPE == OSX ]]; then
        # Mac OS X paths, including Homebrew and MacPorts
        PATH_DIRS=( "${PATH_DIRS[@]}" "/usr/local/bin" "/usr/local/sbin" "/opt/local/bin" "/opt/local/sbin" )
    fi
    __add_to_path "${PATH_DIRS[@]}"

    if [[ -n $BASH_COMPLETION_INSTALLED ]]; then
        # Affects cd behavior
        __add_to_cd_path "." "${HOME}" "${HOME}/src"
    fi

    # SSH client
    if [[ -n $SSH_CLIENT ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Connected from '$COLOR_CYAN_BOLD$(get_ssh_client_ip)$COLOR_NONE
    fi

    # Dev declarations

    # Android SDK
    if [[ -d $HOME/android-sdk ]]; then
        export ANDROID_HOME=$HOME/android-sdk
        __add_to_path "${HOME}/android-sdk/build-tools/$([[ -d "${HOME}/android-sdk/build-tools/" ]] && ls -1 "${HOME}/android-sdk/build-tools/" | tr -d '/' | sort | tail -n 1)" "${HOME}/android-sdk/platform-tools" "${HOME}/android-sdk/tools" "${HOME}/android-ndk" "${HOME}/android-ndk/android-ndk-r10e"
    fi

    if [[ -d $HOME/android-ndk ]]; then
	    if [[ -d $HOME/android-ndk/android-ndk-r10e ]]; then
            export ANDROID_NDK=$HOME/android-ndk/android-ndk-r10e
            export ANDROID_NDK_ROOT=$ANDROID_NDK
            export ANDROID_NDK_REPOSITORY=$HOME/android-ndk
            export NDKROOT=$ANDROID_NDK
            export NDK_MODULE_PATH=$ANDROID_NDK
        else
            export ANDROID_NDK=$HOME/android-ndk
            export ANDROID_NDK_ROOT=$ANDROID_NDK
            export NDKROOT=$ANDROID_NDK
            export NDK_MODULE_PATH=$ANDROID_NDK
        fi
    fi

    # Node
    if [[ -d $HOME/.nvm ]]; then
        export NVM_DIR="$HOME/.nvm"
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            . "$NVM_DIR/nvm.sh"
        fi
        if [[ -s "$NVM_DIR/bash_completion" ]]; then
            . "$NVM_DIR/bash_completion"
        fi

        # Electron-forge
        local NVM_CURRENT ELECTRON_FORGE_COMPLETION

        NVM_CURRENT=`nvm current`
        ELECTRON_FORGE_COMPLETION=$NVM_DIR/versions/node/$NVM_CURRENT/lib/node_modules/electron-forge/node_modules/tabtab/.completions/electron-forge.bash

        if [[ -s "$ELECTRON_FORGE_COMPLETION" ]]; then
            . "$ELECTRON_FORGE_COMPLETION"
        fi
    fi

    # Go
    if [[ $SH_OS_TYPE == OSX ]]; then
        if [[ -d $HOME/src/Go ]]; then
            export GOPATH=$HOME/src/Go
        fi
    fi

    # Torch
    if [[ -n `whence $HOME/torch/install/bin/torch-activate` ]]; then
        [[ -s "$HOME/torch/install/bin/torch-activate" ]] && . $HOME/torch/install/bin/torch-activate
    fi

    # Local declarations
    if [[ -n `whence __zshrc_local_run` ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Executing '$COLOR_GREEN_BOLD$(__bashrc_local)$COLOR_NONE

        __zshrc_local_run "$@"
    fi

    # Global aliases deferred load
    if [[ -n `whence __aliases_load` ]]; then
        __aliases_load "$@"
    fi

    # Local aliases deferred load
    if [[ -n `whence __aliases_local_load` ]]; then
        __aliases_local_load "$@"
    fi

    # Free space
    local FREE_SPACE FREE_SPACE_READABLE
    FREE_SPACE=`df -k / | tail -n 1 | awk '{printf $4}'`
    FREE_SPACE_READABLE=`df -h / | tail -n 1 | awk '{printf $4}' | tr -d [:space:]i`
    FREE_SPACE_READABLE=$COLOR_YELLOW_BOLD$FREE_SPACE_READABLE$COLOR_NONE

    if (( $FREE_SPACE <= 5000000 )); then
        FREE_SPACE_READABLE=$FREE_SPACE_READABLE' '$COLOR_RED_BOLD'WARNING: Low free disk space!!!'$COLOR_NONE
    fi

    [[ $SH_INTERACTIVE ]] && echo
    [[ $SH_INTERACTIVE ]] && echo -e 'Free space: '$FREE_SPACE_READABLE 

    [[ $SH_INTERACTIVE ]] && echo
}

__zshrc_main "$@"
unset -f __zshrc_main

















