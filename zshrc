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

    # SSH configuration
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

    # Homebrew
    if [[ $SH_OS_TYPE == OSX ]]; then
        if [[ -f /opt/homebrew/bin/brew ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Configuring '$COLOR_GREEN_BOLD'Homebrew'$COLOR_NONE
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    elif [[ $SH_OS_TYPE == Linux ]]; then
        if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Configuring '$COLOR_GREEN_BOLD'Linuxbrew'$COLOR_NONE
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
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

    setopt autocd

    zstyle ':completion:*' auto-description 'specify: %d'
    zstyle ':completion:*' completer _expand _complete _correct _approximate
    zstyle ':completion:*' format 'Completing %d'
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*' menu select=2
    # eval "$(dircolors -b)"
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

    if [[ ! -d $HOME/.oh-my-zsh ]]; then
        [[ $SH_INTERACTIVE ]] && echo -e 'Installing '$COLOR_GREEN_BOLD'oh-my-zsh'$COLOR_NONE
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh) --keep-zshrc --unattended"
    fi

    if [[ -d $HOME/.oh-my-zsh ]]; then
        [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD$ZSH'/oh-my-zsh.sh'$COLOR_NONE
        export ZSH="$HOME/.oh-my-zsh"

        ZSH_THEME="amuse"
        COMPLETION_WAITING_DOTS="true"
        DISABLE_UNTRACKED_FILES_DIRTY="true"
        HIST_STAMPS="yyyy-mm-dd"

        plugins=(git mercurial adb nvm node npm python pip macos iterm2 macports)

        source $ZSH/oh-my-zsh.sh
    fi

    # ITerm2 integration
    local ITERM2_INTEGRATION
    if [[ $SH_OS_TYPE == OSX ]]; then
        ITERM2_INTEGRATION=$HOME/.iterm2_shell_integration.zsh
        if [[ -f "$ITERM2_INTEGRATION" ]]; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD$ITERM2_INTEGRATION$COLOR_NONE
            . "$ITERM2_INTEGRATION"
        fi
    fi

    # Zsh completion
    local ZSH_COMPLETION_INSTALLED
    if [[ $SH_OS_TYPE == OSX ]]; then
        if [[ -f /opt/homebrew/bin/brew ]]; then
            if [[ -d /opt/homebrew/share/zsh-completions ]]; then
                ZSH_COMPLETION_INSTALLED=/opt/homebrew/share/zsh-completions
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD'/opt/homebrew/share/zsh-completions'$COLOR_NONE
                FPATH=/opt/homebrew/share/zsh-completions:$FPATH

                autoload -Uz compinit
                compinit
            fi
        fi
    fi

    local PATH_DIRS=( "${HOME}/bin" "${HOME}/.local/bin" )
    if [[ $SH_OS_TYPE == OSX ]]; then
        # Mac OS X paths, including Homebrew and MacPorts
        PATH_DIRS=( "${PATH_DIRS[@]}" "/usr/local/bin" "/usr/local/sbin" "/opt/local/bin" "/opt/local/sbin" "/opt/homebrew/bin" )
    fi
    if [[ $SH_OS_DISTRO == Ubuntu ]]; then
        PATH_DIRS=( "${PATH_DIRS[@]}" "/usr/local/cuda/bin" "/snap/bin" )
    fi
    __add_to_path "${PATH_DIRS[@]}"

    if [[ -n $ZSH_COMPLETION_INSTALLED ]]; then
        # Affects cd behavior
        __add_to_cd_path "." "${HOME}" "${HOME}/src"
    fi

    # SSH client
    if [[ -n $SSH_CLIENT ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Connected from '$COLOR_CYAN_BOLD$(get_ssh_client_ip)$COLOR_NONE
    fi

    export EDITOR=vim

    export GNUTERM=x11

    # WSL X configuration
    if [[ $SH_OS_FLAVOR == WSL ]]; then
        export GDK_DPI_SCALE=2
    fi

    # Dev declarations

    # Windsurf
    if [[ -d $HOME/.codeium/windsurf/bin]]; then
        __add_to_path "${HOME}/.codeium/windsurf/bin"
    fi

    # Android SDK
    if [[ -d $HOME/android-sdk ]]; then
        export ANDROID_HOME=$HOME/android-sdk
        __add_to_path "${HOME}/android-sdk/build-tools/$([[ -d "${HOME}/android-sdk/build-tools/" ]] && ls -1 "${HOME}/android-sdk/build-tools/" | tr -d '/' | sort | tail -n 1)" "${HOME}/android-sdk/platform-tools" "${HOME}/android-sdk/tools" "${HOME}/android-ndk" "${HOME}/android-ndk/android-ndk-r10e"
    fi

    if [[ -d $HOME/android-ndk ]]; then
        if [[ -d $HOME/android-ndk/android-ndk-r10e ]]; then
            export ANDROID_NDK=$HOME/android-ndk/android-ndk-r10e
        else
            export ANDROID_NDK=$HOME/android-ndk
        fi
        export ANDROID_NDK_REPOSITORY=$HOME/android-ndk
        export ANDROID_NDK_ROOT=$ANDROID_NDK
        export NDKROOT=$ANDROID_NDK
        export NDK_MODULE_PATH=$ANDROID_NDK
    fi

    # Node
    if [[ -d $HOME/.nvm ]]; then
        export NVM_DIR="$HOME/.nvm"
    fi
    if [[ -d $NVM_DIR ]]; then
        if [[ -s "$NVM_DIR/nvm.sh" ]]; then
            . "$NVM_DIR/nvm.sh"
        fi
        if [[ -s "$NVM_DIR/bash_completion" ]]; then
            . "$NVM_DIR/bash_completion"
        fi
    fi

    # Bun
    if [[ -d $HOME/.bun ]]; then
        export BUN_INSTALL="$HOME/.bun"
    fi
    if [[ -d $BUN_INSTALL ]]; then
        [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"
        __add_to_path "${BUN_INSTALL}/bin"
    fi

    if [[ -d $HOME/.deno ]]; then
        export DENO_DIR="$HOME/.deno"
    fi
    if [[ -d $DENO_DIR ]]; then
        . "$DENO_DIR/env"
        if [[ ":$FPATH:" != *":/Users/francip/.zsh/completions:"* ]]; then export FPATH="/Users/francip/.zsh/completions:$FPATH"; fi
    fi

    # Ruby
    if [[ $SH_OS_TYPE == OSX ]]; then
        if [[ -d /opt/homebrew/opt/ruby/bin ]]; then
            __add_to_path "/opt/homebrew/opt/ruby/bin" "/opt/homebrew/lib/ruby/gems/3.3.0/bin"
        fi
    fi
    if [[ -d $HOME/.gem ]]; then
        export GEM_HOME="$HOME/.gem"
    elif [[ -d $HOME/gems ]]; then
        export GEM_HOME="$HOME/gems"
    fi
    if [[ -n $GEM_HOME ]]; then
        __add_to_path "${GEM_HOME}/bin"
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

    if [[ -d $HOME/flutter ]]; then
        __add_to_path "${HOME}/flutter/bin" "$HOME/.pub-cache/bin"
    fi

    # Conda
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('/home/francip/miniconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    else
        if [ -f "/home/francip/miniconda3/etc/profile.d/conda.sh" ]; then
            . "/home/francip/miniconda3/etc/profile.d/conda.sh"
        else
            __add_to_path "${HOME}/miniconda3/bin"
        fi
    fi
    unset __conda_setup
    # <<< conda initialize <<<

    # Next.js
    export NEXT_TELEMETRY_DEBUG=1

    # Llama.cpp
    if [[ $SH_OS_DISTRO == Ubuntu ]]; then
        export GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
    fi

    # Local declarations
    if [[ -n `whence __zshrc_local_run` ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Executing '$COLOR_GREEN_BOLD$(__zshrc_local)$COLOR_NONE

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

    # Global dotrc deferred load

    # Node
    # After local dotrc to ensure we don't pick accidentally local dotrc node version
    if [[ -d $NVM_DIR ]]; then
        if [[ $(nvm current) == system ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Switching node from '$COLOR_GREEN_YELLOW'system'$COLOR_YELLOW' to '$COLOR_GREEN_BOLD'nvm default'$COLOR_NONE

            nvm use default
        fi
    fi

    # Free space
    local FREE_SPACE FREE_SPACE_READABLE
    FREE_SPACE=`df -k / | tail -n 1 | awk '{printf $4}'`
    FREE_SPACE_READABLE=`df -h / | tail -n 1 | awk '{printf $4}' | tr -d i`
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
