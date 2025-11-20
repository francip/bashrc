# Source common definitions

__bashrc_main() {
    local SH_SOURCE_FILE SH_SOURCE_DIR SH_SOURCE_FILE_ESCAPED

    if [ -n "$ZSH_VERSION" ]; then
        SH_SOURCE_FILE=${(%):-%x}
    elif [[ -n "$BASH_VERSION" ]]; then
        SH_SOURCE_FILE=${BASH_SOURCE[0]}
    fi

    while [[ -L "$SH_SOURCE_FILE" ]]; do
        SH_SOURCE_FILE=$(readlink "$SH_SOURCE_FILE")
    done

    SH_SOURCE_DIR=$(dirname "$SH_SOURCE_FILE")
    SH_SOURCE_DIR=$(
        cd "$SH_SOURCE_DIR" >/dev/null
        pwd
    )
    SH_SOURCE_FILE=$(basename "$SH_SOURCE_FILE")
    SH_SOURCE_FILE_ESCAPED=${SH_SOURCE_FILE// /_}

    # SH_SOURCE_DIR is a full path to the location of this script

    eval "$(
        cat <<EOF
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
        SH_COLOR_DEFS=$(cat "$SH_SOURCE_DIR/configure_colors")
    fi

    local SH_OS_DEFS
    if [[ -e "$SH_SOURCE_DIR/configure_os" ]]; then
        SH_OS_DEFS=$(cat "$SH_SOURCE_DIR/configure_os")
    fi

    eval "$(
        cat <<EOF
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
    [[ $SH_INTERACTIVE ]] && echo -e 'Configuring environment for '$COLOR_GREEN_BOLD'Bash '${BASH_VERSINFO[0]}'.'${BASH_VERSINFO[1]}'.'${BASH_VERSINFO[2]}$COLOR_NONE' on '$COLOR_GREEN_BOLD$SH_OS_DISTRO$COLOR_NONE' '$COLOR_GREEN_BOLD$SH_OS_RELEASE$COLOR_NONE' ('$COLOR_GREEN_BOLD$SH_OS_TYPE$COLOR_NONE')'

    # SSH configuration
    if [[ $SH_OS_TYPE == Windows ]]; then
        export SSH_AUTH_SOCK=/tmp/.ssh-socket
        ssh-add -l >/dev/null 2>&1
        if [[ $? = 2 ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Creating new ssh-agent'
            rm -f /tmp/.ssh-script /tmp/.ssh-agent-pid /tmp/.ssh-socket
            ssh-agent -a $SSH_AUTH_SOCK >/tmp/.ssh-script
            . /tmp/.ssh-script
            [[ $SH_INTERACTIVE ]] && echo $SSH_AGENT_PID >/tmp/.ssh-agent-pid
        fi
    fi

    if [[ $SH_OS_TYPE == Linux ]]; then
        if [[ -z "$(pgrep -u $USER ssh-agent)" ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'SSH agent '$COLOR_YELLOW_BOLD'not running'$COLOR_NONE'. Starting new one...'
            rm -rf /tmp/ssh-* 2>/dev/null
            eval $(ssh-agent -s) >/dev/null
        else
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'SSH agent '$COLOR_GREEN_BOLD'running'$COLOR_NONE'. Connecting...'
            export SSH_AGENT_PID=$(pgrep -u $USER ssh-agent)
            export SSH_AUTH_SOCK=$(find /tmp/ssh-* -name agent.\* 2>/dev/null)
        fi
    fi

    # Only add keys in interactive shell
    if [[ $SH_INTERACTIVE ]]; then
        ssh-add >/dev/null 2>&1

        if [[ -f "${HOME}/.ssh/id_rsa_personal" ]]; then
            if [[ $(ssh-add -l | grep -i id_rsa_personal | wc -l) -lt 1 ]]; then
                if [[ $SH_OS_TYPE == OSX ]]; then
                    ssh-add -K ${HOME}/.ssh/id_rsa_personal >/dev/null 2>&1
                else
                    ssh-add ${HOME}/.ssh/id_rsa_personal >/dev/null 2>&1
                fi
            fi
        fi
    fi

    export LANG=en_US.UTF-8
    export LC_ALL=en_US.UTF-8

    # Homebrew
    if [[ $SH_OS_TYPE == OSX ]]; then
        if [[ -f /opt/homebrew/bin/brew ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Configuring '$COLOR_GREEN_BOLD'Homebrew'$COLOR_NONE
            export HOMEBREW_NO_ENV_HINTS=1
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    elif [[ $SH_OS_TYPE == Linux ]]; then
        if [[ -f /home/linuxbrew/.linuxbrew/bin/brew ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Configuring '$COLOR_GREEN_BOLD'Linuxbrew'$COLOR_NONE
            export HOMEBREW_NO_ENV_HINTS=1
            eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        fi
    fi

    local BREW_DIR

    BREW_DIR=$(brew --prefix 2>>/dev/null)
    if [ -z "$BREW_DIR" ]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e $COLOR_YELLOW_BOLD'Homebrew'$COLOR_NONE' not installed'
    else
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e $COLOR_GREEN_BOLD'Homebrew'$COLOR_NONE' installed at '$COLOR_GREEN_BOLD$BREW_DIR$COLOR_NONE
    fi

    # Source additional global, local, and personal definitions
    [[ $SH_INTERACTIVE ]] && echo
    __include_files "${HOME}/.bashrc.local" "${HOME}/.bashrc_local" "${SH_SOURCE_DIR}/aliases" "${HOME}/.aliases.local" "${HOME}/.aliases_local"

    # ITerm2 integration
    local ITERM2_INTEGRATION
    if [[ $SH_OS_TYPE == OSX ]]; then
        ITERM2_INTEGRATION=$HOME/.iterm2_shell_integration.bash
        if [[ -f "$ITERM2_INTEGRATION" ]]; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD$ITERM2_INTEGRATION$COLOR_NONE
            . "$ITERM2_INTEGRATION"
        fi
    fi

    # Bash completion
    local BASH_COMPLETION_INSTALLED BASH_COMPLETION_INSTALLED_COMMAND
    if [[ $SH_OS_TYPE == OSX ]]; then
        BASH_COMPLETION_INSTALLED_COMMAND=_brew_completions
    elif [[ $SH_OS_TYPE == Linux ]]; then
        BASH_COMPLETION_INSTALLED_COMMAND=_init_completion
    fi
    BASH_COMPLETION_INSTALLED=$(type -t ${BASH_COMPLETION_INSTALLED_COMMAND})

    if [[ -z $BASH_COMPLETION && -z $BASH_COMPLETION_INSTALLED ]]; then
        if [[ $SH_OS_TYPE == OSX ]]; then
            # Bash completion for Mac OS X (from Homebrew or MacPorts)
            if [[ -f /usr/local/etc/bash_completion ]]; then
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD'/usr/local/etc/bash_completion'$COLOR_NONE
                . /usr/local/etc/bash_completion
            elif [[ -f /opt/local/etc/profile.d/bash_completion.sh ]]; then
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD'/opt/local/etc/profile.d/bash_completion.sh'$COLOR_NONE
                . /opt/local/etc/profile.d/bash_completion.sh
            elif [[ -f ${BREW_DIR}/bin/brew ]]; then
                if [[ -f ${BREW_DIR}/etc/profile.d/bash_completion.sh ]]; then
                    [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD$BREW_DIR'/etc/profile.d/bash_completion.sh'$COLOR_NONE
                    . ${BREW_DIR}/etc/profile.d/bash_completion.sh
                fi
            fi
        elif [[ $SH_OS_TYPE == Linux ]]; then
            # Bash completion for Linux
            if [[ -f /etc/bash_completion ]]; then
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD'/etc/bash_completion'$COLOR_NONE
                . /etc/bash_completion
            fi
        fi

        BASH_COMPLETION_INSTALLED=$(type -t ${BASH_COMPLETION_INSTALLED_COMMAND})

        if [[ -z $BASH_COMPLETION && -z $BASH_COMPLETION_INSTALLED ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Bash completion '$COLOR_RED_BOLD'not configured'$COLOR_NONE
        fi
    fi

    # Git completion
    local GIT_COMPLETION
    if [[ -z $(type -t __git_ps1) ]]; then
        GIT_COMPLETION=$(type -P git-completion.bash)

        if [[ -z $GIT_COMPLETION ]]; then
            GIT_COMPLETION=$HOME/bin/git-completion.bash
        fi

        if [[ -f "$GIT_COMPLETION" ]]; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD$GIT_COMPLETION$COLOR_NONE
            . "$GIT_COMPLETION"
        fi
    fi

    # ADB completion
    local ADB_COMPLETION
    ADB_COMPLETION=$(type -P adb.bash)
    if [[ -z $ADB_COMPLETION ]]; then
        ADB_COMPLETION=$HOME/bin/adb.bash
    fi

    if [[ -f "$ADB_COMPLETION" ]]; then
        [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_GREEN_BOLD$ADB_COMPLETION$COLOR_NONE
        . "$ADB_COMPLETION"
    fi

    local PATH_DIRS=("${HOME}/bin" "${HOME}/.local/bin" "${SH_SOURCE_DIR}/scripts")
    if [[ $SH_OS_TYPE == OSX ]]; then
        # Mac OS X paths, including Homebrew and MacPorts
        PATH_DIRS=("${PATH_DIRS[@]}" "/usr/local/bin" "/usr/local/sbin" "/opt/local/bin" "/opt/local/sbin" "${BREW_DIR}/bin")
    fi
    if [[ $SH_OS_DISTRO == Ubuntu ]]; then
        PATH_DIRS=("${PATH_DIRS[@]}" "/usr/local/cuda/bin" "/snap/bin")
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

    # Prompt
    local COLOR_ROOT_INVERT VERSION_CONTROL_PROMPT

    COLOR_ROOT_INVERT=$COLOR_GREEN_INVERT
    if [[ "$(whoami)" == "root" ]]; then
        COLOR_ROOT_INVERT=$COLOR_RED_INVERT
    fi

    # Show version controlled repository status.
    # vcprompt is used if installed, otherwise __git_ps1 will be tried as well.
    __version_control_ps1() {
        if [[ $(which vcprompt 2>/dev/null) ]]; then
            vcprompt -f "[%n %b] "
        elif [[ -n $(type -t __git_ps1) ]]; then
            # Sadly on big repositories this makes the prompt really slow
            #export GIT_PS1_SHOWDIRTYSTATE=true
            #export GIT_PS1_SHOWUNTRACKEDFILES=true
            #export GIT_PS1_SHOWUPSTREAM=auto

            __git_ps1 '[git %s] '
        fi
    }

    VERSION_CONTROL_PROMPT='$(__version_control_ps1)'

    export PS1='\['$COLOR_BOLD'\]\['$COLOR_ROOT_INVERT'\]\u\['$COLOR_NONE'\] \['$COLOR_BOLD'\]\['$COLOR_YELLOW_INVERT'\]\h\['$COLOR_NONE'\] \['$COLOR_CYAN_BOLD'\]\w\['$COLOR_NONE'\] \['$COLOR_MAGENTA_BOLD'\]'$VERSION_CONTROL_PROMPT'\['$COLOR_NONE'\]\$ '

    # Color directories
    if [[ $SH_OS_TYPE == OSX ]]; then
        # Mac OS X settings
        #export CLICOLOR=1
        export LSCOLORS=GxFxCxDxBxegedabagaced
    fi

    if [[ $SH_OS_TYPE == Linux ]]; then
        # Linux settings
        export LS_COLORS='di=01;36'
    fi

    # Misc declarations
    if [[ $SH_OS_TYPE == Linux ]]; then
        if [[ $SH_OS_DISTRO == Ubuntu ]]; then
            if [[ -z $SHELL ]]; then
                # Ubuntu does not always define it for some reason
                export SHELL=/usr/bin/env bash
            fi
        fi
    fi

    export EDITOR=vim

    # WSL X configuration
    if [[ $SH_OS_FLAVOR == WSL ]]; then
        export GDK_DPI_SCALE=2
    fi

    # Dev declarations

    # Windsurf
    if [[ -d $HOME/.codeium/windsurf/bin ]]; then
        __add_to_path "${HOME}/.codeium/windsurf/bin"
    fi

    # Antigravity
    if [[ -d $HOME/.antigravity/antigravity/bin ]]; then
        __add_to_path "${HOME}/.antigravity/antigravity/bin"
    fi

    # Claude
    if [[ -d $HOME/.claude/local ]]; then
        __add_to_path "${HOME}/.claude/local"
    fi

    # Android SDK
    if [[ -d $HOME/android-sdk ]]; then
        export ANDROID_HOME=$HOME/android-sdk
    fi

    if [[ -d $HOME/Library/Android/sdk ]]; then
        export ANDROID_HOME=$HOME/Library/Android/sdk
    fi

    if [[ -n $ANDROID_HOME ]]; then
        __add_to_path "${ANDROID_HOME}/build-tools/$([[ -d "${ANDROID_HOME}/build-tools/" ]] && ls -1 "${ANDROID_HOME}/build-tools/" | tr -d '/' | sort -V | tail -n 1)" "${ANDROID_HOME}/platform-tools" "${ANDROID_HOME}/tools"
    fi

    if [[ -d $HOME/android-ndk ]]; then
        export ANDROID_NDK=$HOME/android-ndk
    fi

    if [[ -d $ANDROID_HOME/ndk ]]; then
        export ANDROID_NDK=$ANDROID_HOME/ndk
    fi

    if [[ -n $ANDROID_NDK ]]; then
        export ANDROID_NDK_REPOSITORY=$ANDROID_NDK
        export ANDROID_NDK_ROOT=$ANDROID_NDK
        export NDKROOT=$ANDROID_NDK
        export NDK_MODULE_PATH=$ANDROID_NDK
        __add_to_path "${ANDROID_NDK}/$([[ -d "${ANDROID_NDK}/" ]] && ls -1 "${ANDROID_NDK}/" | tr -d '/' | sort -V | tail -n 1)"
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
        __add_to_path "${BUN_INSTALL}/bin"
    fi

    # Deno
    if [[ -d $HOME/.deno ]]; then
        export DENO_DIR="$HOME/.deno"
    fi
    if [[ -d $DENO_DIR ]]; then
        . "$DENO_DIR/env"
        . $HOME/.local/share/bash-completion/completions/deno.bash
    fi

    # Ruby
    local SH_BREW_RUBY SH_DEFAULT_GEM_HOME
    if [[ $SH_OS_TYPE == OSX ]]; then
        SH_BREW_RUBY="${BREW_DIR}/opt/ruby/bin/ruby"
        if [[ -x $SH_BREW_RUBY ]]; then
            __add_to_path "${BREW_DIR}/opt/ruby/bin"
            SH_DEFAULT_GEM_HOME=$($SH_BREW_RUBY -e 'require "rubygems"; print Gem.default_dir' 2>/dev/null)
        fi
    fi
    if [[ -z $GEM_HOME ]]; then
        if [[ -n $SH_DEFAULT_GEM_HOME && -d $SH_DEFAULT_GEM_HOME ]]; then
            export GEM_HOME="$SH_DEFAULT_GEM_HOME"
        elif [[ -d $HOME/.gem ]]; then
            export GEM_HOME="$HOME/.gem"
        elif [[ -d $HOME/gems ]]; then
            export GEM_HOME="$HOME/gems"
        fi
    fi
    if [[ -n $GEM_HOME ]]; then
        __add_to_path "${GEM_HOME}/bin"
    fi

    # Go
    if [[ $SH_OS_TYPE == OSX ]]; then
        if [[ -d $HOME/go ]]; then
            export GOPATH=$HOME/go
        fi
    fi

    # Conda
    # >>> conda initialize >>>
    # !! Contents within this block are managed by 'conda init' !!
    __conda_setup="$('$HOME/miniconda3/bin/conda' 'shell.bash' 'hook' 2>/dev/null)"
    if [ $? -eq 0 ]; then
        eval "$__conda_setup"
    fi
    unset __conda_setup
    # <<< conda initialize <<<

    # Next.js
    export NEXT_TELEMETRY_DEBUG=1

    # Python
    export PYTHONPATH=./

    # Rust
    if [[ -d $HOME/.cargo ]]; then
        . "$HOME/.cargo/env"
    fi

    # Llama.cpp
    if [[ $SH_OS_DISTRO == Ubuntu ]]; then
        export GGML_CUDA_ENABLE_UNIFIED_MEMORY=1
    fi

    # Local declarations
    if [[ -n $(type -t __bashrc_local_run) ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Executing '$COLOR_GREEN_BOLD$(__bashrc_local)$COLOR_NONE

        __bashrc_local_run "$@"
    fi

    # Global aliases deferred load
    if [[ -n $(type -t __aliases_load) ]]; then
        __aliases_load "$@"
    fi

    # Local aliases deferred load
    if [[ -n $(type -t __aliases_local_load) ]]; then
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
    FREE_SPACE=$(df -k / | tail -n 1 | awk '{printf $4}')
    FREE_SPACE_READABLE=$(df -h / | tail -n 1 | awk '{printf $4}' | tr -d i)
    FREE_SPACE_READABLE=$COLOR_YELLOW_BOLD$FREE_SPACE_READABLE$COLOR_NONE

    if (($FREE_SPACE <= 5000000)); then
        FREE_SPACE_READABLE=$FREE_SPACE_READABLE' '$COLOR_RED_BOLD'WARNING: Low free disk space!!!'$COLOR_NONE
    fi

    [[ $SH_INTERACTIVE ]] && echo
    [[ $SH_INTERACTIVE ]] && echo -e 'Free space: '$FREE_SPACE_READABLE

    [[ $SH_INTERACTIVE ]] && echo
}

__bashrc_main "$@"
unset -f __bashrc_main
