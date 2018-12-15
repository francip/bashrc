#!/bin/bash

# This file is not intended for direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then exit; fi

# Source common definitions

__bashrc_main() {
    local BASH_SOURCE_FILE BASH_SOURCE_DIR BASH_SOURCE_FILE_ESCAPED

    BASH_SOURCE_FILE=${BASH_SOURCE[0]}
    while [[ -L "$BASH_SOURCE_FILE" ]]; do
        BASH_SOURCE_FILE=$(readlink "$BASH_SOURCE_FILE")
    done

    BASH_SOURCE_DIR=$(dirname "$BASH_SOURCE_FILE")
    BASH_SOURCE_DIR=`cd "$BASH_SOURCE_DIR" >/dev/null; pwd`
    BASH_SOURCE_FILE=$(basename "$BASH_SOURCE_FILE")
    BASH_SOURCE_FILE_ESCAPED=${BASH_SOURCE_FILE// /_}

    # BASH_SOURCE_DIR is a full path to the location of this script

    eval "$(cat <<EOF
        __get_${BASH_SOURCE_FILE_ESCAPED}_dir() {
          echo $BASH_SOURCE_DIR
        }
        __get_${BASH_SOURCE_FILE_ESCAPED}_file() {
          echo $BASH_SOURCE_FILE
        }
EOF
)"

    local BASH_COLOR_DEFS
    if [[ -e "$BASH_SOURCE_DIR/configure_colors" ]]; then
        BASH_COLOR_DEFS=`cat "$BASH_SOURCE_DIR/configure_colors"`
    fi

    local BASH_OS_DEFS
    if [[ -e "$BASH_SOURCE_DIR/configure_os" ]]; then
        BASH_OS_DEFS=`cat "$BASH_SOURCE_DIR/configure_os"`
    fi

    eval "$(cat <<EOF
        _bash_color_definitions() {
            echo "$BASH_COLOR_DEFS"
        }
        _bash_os_definitions() {
            echo "$BASH_OS_DEFS"
        }
EOF
)"

    eval "$(_bash_color_definitions)"
    eval "$(_bash_os_definitions)"

    local BASH_INTERACTIVE

    case $- in
    *i*)
        # interactive shell
        BASH_INTERACTIVE=1
        ;;
    esac

    . "${BASH_SOURCE_DIR}/bashrc_helpers"

    [ $BASH_INTERACTIVE ] && echo
    [ $BASH_INTERACTIVE ] && echo -e 'Configuring environment for '$COLOR_GREEN_BOLD'Bash '${BASH_VERSINFO[0]}'.'${BASH_VERSINFO[1]}'.'${BASH_VERSINFO[2]}$COLOR_NONE' on '$COLOR_GREEN_BOLD$BASH_OS_DISTRO$COLOR_NONE' '$COLOR_GREEN_BOLD$BASH_OS_RELEASE$COLOR_NONE' ('$COLOR_GREEN_BOLD$BASH_OS_TYPE$COLOR_NONE')'

    if [[ $BASH_OS_TYPE == Windows ]]; then
        export SSH_AUTH_SOCK=/tmp/.ssh-socket
        ssh-add -l >/dev/null 2>&1
        if [ $? = 2 ]; then
            [ $BASH_INTERACTIVE ] && echo
            [ $BASH_INTERACTIVE ] && echo -e 'Creating new ssh-agent'
            rm -f /tmp/.ssh-script /tmp/.ssh-agent-pid /tmp/.ssh-socket
            ssh-agent -a $SSH_AUTH_SOCK > /tmp/.ssh-script
            . /tmp/.ssh-script
            [ $BASH_INTERACTIVE ] && echo $SSH_AGENT_PID > /tmp/.ssh-agent-pid
        fi
    fi

    if [[ $BASH_OS_TYPE == Linux ]]; then
        if [ -z "$(pgrep ssh-agent)" ]; then
            rm -rf /tmp/ssh-*
            eval $(ssh-agent -s) >/dev/null
        else
            export SSH_AGENT_PID=$(pgrep ssh-agent)
            export SSH_AUTH_SOCK=$(find /tmp/ssh-* -name agent.* 2>/dev/null)
        fi
    fi

    ssh-add >/dev/null 2>&1

    if [[ -f "${HOME}/.ssh/id_rsa_personal" ]]; then
        if [[ `ssh-add -l | grep -i id_rsa_personal | wc -l` -lt 1 ]]; then
            if [[ $BASH_OS_TYPE == OSX ]]; then
                ssh-add -K ~/.ssh/id_rsa_personal >/dev/null 2>&1
            else
                ssh-add ~/.ssh/id_rsa_personal >/dev/null 2>&1
            fi
        fi
    fi

    # Source additional global, local, and personal definitions
    [ $BASH_INTERACTIVE ] && echo
    __include_files "/etc/bashrc" "${HOME}/.bashrc_local" "${BASH_SOURCE_DIR}/aliases" "${HOME}/.aliases_local"

    local BASH_COMPLETION_INSTALLED
    BASH_COMPLETION_INSTALLED=`type -t _init_completion`

    # Bash completion
    if [[ -z $BASH_COMPLETION && -z $BASH_COMPLETION_INSTALLED ]]; then
        if [[ $BASH_OS_TYPE == OSX ]]; then
            # Bash completion for Mac OS X (from Homebrew or MacPorts)
            if [[ -f /usr/local/etc/bash_completion ]]; then
                [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD'/usr/local/etc/bash_completion'$COLOR_NONE
                . /usr/local/etc/bash_completion
            elif [[ -f /opt/local/etc/profile.d/bash_completion.sh ]]; then
                [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD'/opt/local/etc/profile.d/bash_completion.sh'$COLOR_NONE
                . /opt/local/etc/profile.d/bash_completion.sh
            fi
        elif [[ $BASH_OS_TYPE == Linux ]]; then
            # Bash completion for Linux
            if [[ -f /etc/bash_completion ]]; then
                [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD'/etc/bash_completion'$COLOR_NONE
                . /etc/bash_completion
            fi
        fi

        BASH_COMPLETION_INSTALLED=`type -t _init_completion`

        if [[ -z $BASH_COMPLETION && -z $BASH_COMPLETION_INSTALLED ]]; then
            [ $BASH_INTERACTIVE ] && echo -e 'Bash completion '$COLOR_RED_BOLD'not configured'$COLOR_NONE
        fi
    fi

    local GIT_COMPLETION ADB_COMPLETION

    # Git completion
    if [[ -z `type -t __git_ps1` ]]; then
        GIT_COMPLETION=`type -P git-completion.bash`

        if [[ -z $GIT_COMPLETION ]]; then
            GIT_COMPLETION=$HOME/bin/git-completion.bash
        fi

        if [[ -f "$GIT_COMPLETION" ]]; then
            [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD$GIT_COMPLETION$COLOR_NONE
            . "$GIT_COMPLETION"
        fi
    fi

    # ADB completion
    ADB_COMPLETION=`type -P adb.bash`
    if [[ -z $ADB_COMPLETION ]]; then
        ADB_COMPLETION=$HOME/bin/adb.bash
    fi

    if [[ -f "$ADB_COMPLETION" ]]; then
        [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD$ADB_COMPLETION$COLOR_NONE
        . "$ADB_COMPLETION"
    fi

    local PATH_DIRS=( "${HOME}/bin" )
    if [[ $BASH_OS_TYPE == OSX ]]; then
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
        [ $BASH_INTERACTIVE ] && echo
        [ $BASH_INTERACTIVE ] && echo -e 'Connected from '$COLOR_CYAN_BOLD$(get_ssh_client_ip)$COLOR_NONE
    fi

    # Prompt
    local COLOR_ROOT_INVERT VERSION_CONTROL_PROMPT

    COLOR_ROOT_INVERT=$COLOR_GREEN_INVERT
    if [[ "`whoami`" == "root" ]]; then
        COLOR_ROOT_INVERT=$COLOR_RED_INVERT
    fi

    # Show version controlled repository status.
    # vcprompt is used if installed, otherwise __git_ps1 will be tried as well.
    __version_control_ps1() {
        if [[ $(which vcprompt 2>/dev/null) ]]; then
            vcprompt -f "[%n %b] "
        elif [[ -n `type -t __git_ps1` ]]; then
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
    if [[ $BASH_OS_TYPE == OSX ]]; then
        # Mac OS X settings
        #export CLICOLOR=1
        export LSCOLORS=GxFxCxDxBxegedabagaced
    fi

    if [[ $BASH_OS_TYPE == Linux ]]; then
        # Linux settings
        export LS_COLORS='di=01;36'
    fi

    # Misc declarations
    if [[ $BASH_OS_TYPE == Linux ]]; then
        if [[ $BASH_OS_DISTRO == Ubuntu ]]; then
            if [[ -z $SHELL ]]; then
                # Ubuntu does not always define it for some reason
                export SHELL=/bin/bash
            fi
        fi
    fi

    export EDITOR=vim

    export GNUTERM=x11

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
        [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    fi

    # Python
    if [[ $BASH_OS_TYPE == Linux ]]; then
        if [[ $BASH_OS_DISTRO == Raspbian ]]; then
            if [[ -f /usr/local/bin/virtualenvwrapper.sh ]]; then
                export WORKON_HOME=$HOME/.virtualenvs
                source /usr/local/bin/virtualenvwrapper.sh
            fi
        fi
    fi

    # Go
    if [[ $BASH_OS_TYPE == OSX ]]; then
        if [[ -d $HOME/src/Go ]]; then
            export GOPATH=$HOME/src/Go
        fi
    fi

    # Torch
    if [[ -n `type -t $HOME/torch/install/bin/torch-activate` ]]; then
        [ -s "$HOME/torch/install/bin/torch-activate" ] && . $HOME/torch/install/bin/torch-activate
    fi

    # Local declarations
    if [[ -n `type -t __bashrc_local_run` ]]; then
        [ $BASH_INTERACTIVE ] && echo -e 'Executing '$COLOR_GREEN_BOLD$(__bashrc_local)$COLOR_NONE

        __bashrc_local_run "$@"
    fi

    [ $BASH_INTERACTIVE ] && echo
}

__bashrc_main "$@"
unset __bashrc_main
