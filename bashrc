#!/bin/bash

# This file is not intended for direct execution
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then exit; fi

__bashrc_main() {
    local BASH_SOURCE_FILE BASH_SOURCE_DIR

    BASH_SOURCE_FILE=${BASH_SOURCE[0]}
    while [[ -L "$BASH_SOURCE_FILE" ]]; do
        BASH_SOURCE_FILE=$(readlink "$BASH_SOURCE_FILE")
    done

    BASH_SOURCE_DIR=$(dirname "$BASH_SOURCE_FILE")
    BASH_SOURCE_DIR=`cd $BASH_SOURCE_DIR >/dev/null; pwd`
    BASH_SOURCE_FILE=$(basename "$BASH_SOURCE_FILE")

    # BASH_SOURCE_DIR is a full path to the location of this script

    eval "$(cat <<EOF
        __get_bashrc_dir() {
          echo $BASH_SOURCE_DIR
        }
        __get_bashrc_file() {
          echo $BASH_SOURCE_FILE
        }
EOF
)"

    local BASH_COLOR_DEFS
    if [[ -e $BASH_SOURCE_DIR/configure_colors ]]; then
        BASH_COLOR_DEFS=`cat $BASH_SOURCE_DIR/configure_colors`
    fi

    local BASH_OS_DEFS
    if [[ -e $BASH_SOURCE_DIR/configure_os ]]; then
        BASH_OS_DEFS=`cat $BASH_SOURCE_DIR/configure_os`
    fi

    eval "$(cat <<EOF
        _bash_color_definitions () {
            echo "$BASH_COLOR_DEFS"
        }
        _bash_os_definitions () {
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

    [ $BASH_INTERACTIVE ] && echo
    [ $BASH_INTERACTIVE ] && echo -e 'Configuring environment for '$COLOR_GREEN_BOLD'Bash '$BASH_VERSION$COLOR_NONE' on '$COLOR_GREEN_BOLD$BASH_OS_DISTRO$COLOR_NONE' '$COLOR_GREEN_BOLD$BASH_OS_RELEASE$COLOR_NONE' ('$COLOR_GREEN_BOLD$BASH_OS_TYPE$COLOR_NONE')'
    [ $BASH_INTERACTIVE ] && echo

    local BASH_FILES BASH_FILE

    # Source global, local, and personal definitions
    BASH_FILES=( /etc/bashrc $HOME/bashrc.local $BASH_SOURCE_DIR/aliases $HOME/aliases.local )
    for BASH_FILE in ${BASH_FILES[@]}; do
        if [[ -f $BASH_FILE ]]; then
            [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD$BASH_FILE$COLOR_NONE
            . $BASH_FILE
        fi
    done

    # Bash completion for Mac OS X (from Brew)
    if [[ $BASH_OS_TYPE == MacOSX ]]; then
        if [[ -f /usr/local/etc/bash_completion ]]; then
            [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD'/usr/local/etc/bash_completion'$COLOR_NONE
            . /usr/local/etc/bash_completion
        fi
    fi

    # Bash completion for Linux
    if [[ $BASH_OS_TYPE == Linux ]]; then
        if [[ -z $BASH_COMPLETION ]]; then
            if [[ -f /etc/bash_completion ]]; then
                [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD'/etc/bash_completion'$COLOR_NONE
                . /etc/bash_completion
            fi
        fi
    fi

    local GIT_COMPLETION ADB_COMPLETION BUCK_COMPLETION

    # Git completion
    if [[ -z `type -t __git_ps1` ]]; then
        GIT_COMPLETION=`type -P git-completion.bash`

        if [[ -z $GIT_COMPLETION ]]; then
            GIT_COMPLETION=$HOME/bin/git-completion.bash
        fi

        if [[ -f $GIT_COMPLETION ]]; then
            [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD$GIT_COMPLETION$COLOR_NONE
            . $GIT_COMPLETION
        fi
    fi

    # ADB completion
    ADB_COMPLETION=`type -P adb.bash`
    if [[ -z $ADB_COMPLETION ]]; then
        ADB_COMPLETION=$HOME/bin/adb.bash
    fi

    if [[ -f $ADB_COMPLETION ]]; then
        [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD$ADB_COMPLETION$COLOR_NONE
        . $ADB_COMPLETION
    fi

    # Use hard target resolution in Buck autocompletion
    export BUCK_COMPLETION_HARDTARGETRESOLUTION=true
    export BUCK_ENABLE_EXTENSIONS=false

    # BUCK completion
    BUCK_COMPLETION=`type -P buck-completion.bash`
    if [[ -z $BUCK_COMPLETION ]]; then
        BUCK_COMPLETION=$HOME/bin/buck-completion.bash
    fi

    if [[ -f $BUCK_COMPLETION ]]; then
        [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD$BUCK_COMPLETION$COLOR_NONE
        . $BUCK_COMPLETION
    fi

    BUCK_EXTENSIONS=`type -P buck-extensions.sh`
    if [[ -z $BUCK_EXTENSIONS ]]; then
        BUCK_EXTENSIONS=$HOME/bin/buck-extensions.sh
    fi

    if [[ -f $BUCK_EXTENSIONS ]]; then
        [ $BASH_INTERACTIVE ] && echo -e 'Loading '$COLOR_GREEN_BOLD$BUCK_EXTENSIONS$COLOR_NONE
        . $BUCK_EXTENSIONS
    fi

    [ $BASH_INTERACTIVE ] && echo

    [ $BASH_INTERACTIVE ] && echo -e 'Adding to the '$COLOR_CYAN_BOLD'path'$COLOR_NONE':'

    local PATH_DIRS PATH_DIR PATH_DIRS_PREFIX

    PATH_DIRS=( $HOME/android-sdk/build-tools/$([ -d $HOME/android-sdk/build-tools/ ] && ls -1 $HOME/android-sdk/build-tools/ | tr -d '/' | sort | tail -n 1) $HOME/android-sdk/platform-tools $HOME/android-sdk/tools $HOME/android-ndk $HOME/bin )
    if [[ $BASH_OS_TYPE == MacOSX ]]; then
        # Mac OS X paths, including Homebrew
        PATH_DIRS=( ${PATH_DIRS[@]} /usr/local/bin /usr/local/sbin )
    fi

    for PATH_DIR in ${PATH_DIRS[@]}; do
        if [[ -d $PATH_DIR ]]; then
            if [[ ":$PATH:" != *":$PATH_DIR:"* ]]; then
                [ $BASH_INTERACTIVE ] && echo -e '  '$COLOR_YELLOW_BOLD$PATH_DIR$COLOR_NONE
                if [[ -n $PATH_DIRS_PREFIX ]]; then
                    PATH_DIRS_PREFIX=$PATH_DIRS_PREFIX:$PATH_DIR
                else
                    PATH_DIRS_PREFIX=$PATH_DIR
                fi
            fi
        fi
    done

    if [[ -n $PATH_DIRS_PREFIX ]]; then
        if [[ -n $PATH ]]; then
            export PATH=$PATH_DIRS_PREFIX:$PATH
        else
            export PATH=$PATH_DIRS_PREFIX
        fi
    fi

    [ $BASH_INTERACTIVE ] && echo

    # Affects cd behavior
    [ $BASH_INTERACTIVE ] && echo -e 'Configuring '$COLOR_CYAN_BOLD'cd'$COLOR_NONE' to cycle through:'

    local CDPATH_DIRS CDPATH_DIR CDPATH_DIRS_PREFIX

    CDPATH_DIRS=( . $HOME $HOME/Projects $HOME/local )
    for CDPATH_DIR in ${CDPATH_DIRS[@]}; do
        if [[ -d $CDPATH_DIR ]]; then
            if [[ ":$CDPATH:" != *":$CDPATH_DIR:"* ]]; then
                [ $BASH_INTERACTIVE ] && echo -e '  '$COLOR_YELLOW_BOLD$CDPATH_DIR$COLOR_NONE
                if [[ -n $CDPATH_DIRS_PREFIX ]]; then
                    CDPATH_DIRS_PREFIX=$CDPATH_DIRS_PREFIX:$CDPATH_DIR
                else
                    CDPATH_DIRS_PREFIX=$CDPATH_DIR
                fi
            fi
        fi
    done

    if [[ -n $CDPATH_DIRS_PREFIX ]]; then
        if [[ -n $CDPATH ]]; then
            export CDPATH=$CDPATH_DIRS_PREFIX:$CDPATH
        else
            export CDPATH=$CDPATH_DIRS_PREFIX
        fi
    fi

    # SSH client
    if [[ -n $SSH_CLIENT ]]; then
        [ $BASH_INTERACTIVE ] && echo
        [ $BASH_INTERACTIVE ] && echo -e 'Connected from '$COLOR_CYAN_BOLD$(get_ssh_client_ip)$COLOR_NONE
    fi

    [ $BASH_INTERACTIVE ] && echo

    # Prompt
    local COLOR_ROOT_INVERT VERSION_CONTROL_PROMPT

    COLOR_ROOT_INVERT=$COLOR_GREEN_INVERT
    if [[ "`whoami`" == "root" ]]; then
        COLOR_ROOT_INVERT=$COLOR_RED_INVERT
    fi

    # Show version controlled repository status.
    # vcprompt is used if installed, otherwise __git_ps1 will be tried as well.
    __version_control_ps1 () {
        if [[ $(which vcprompt) ]]; then
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
    if [[ $BASH_OS_TYPE == MacOSX ]]; then
        # Mac OS X settings
        #export CLICOLOR=1
        export LSCOLORS=GxFxCxDxBxegedabagaced
    fi

    if [[ $BASH_OS_TYPE == Linux ]]; then
        # Linux settings
        export LS_COLORS='di=01;36'
    fi

    # Misc declarations
    if [[ $BASH_OS_TYPE == MacOSX ]]; then
        # Required for Homebrew version of Meld
        #export PYTHONPATH=/usr/local/lib/python2.7/site-packages:/Library/Python/2.7/site-packages:$PYTHONPATH

        # set the number of open files to be 1024
        #ulimit -S -n 1024

        # Required for Muse SDK
	    export PATH="$PATH:/Applications/Muse"
    	export DYLD_LIBRARY_PATH="$DYLD_LIBRARY_PATH:/Applications/Muse"
    fi

    if [[ $BASH_OS_TYPE == Linux ]]; then
        if [[ $BASH_OS_DISTRO == Ubuntu ]]; then
            if [[ -z $SHELL ]]; then
                # Ubuntu does not always define it for some reason
                export SHELL=/bin/bash
            fi
        fi

        if [[ $BASH_OS_DISTRO == CentOS ]]; then
            if [[ $COLORTERM == gnome-terminal ]]; then
                # We should also check for the CentOS/Gnome version here
                # but for now just do it evey time
                # Check if ssh-add -l contains .ssh/id_rsa
                if [[ `ssh-add -l | grep -i .ssh/id_rsa | wc -l` < 1 ]]; then
                    ssh-add
                fi
            fi
        fi
    fi

    export EDITOR=vim

    export GNUTERM=x11

    if [[ -d $HOME/android-sdk ]]; then
        export ANDROID_HOME=$HOME/android-sdk
    fi

    if [[ -d $HOME/android-ndk ]]; then
        export ANDROID_NDK=$HOME/android-ndk
        export ANDROID_NDK_ROOT=$ANDROID_NDK
        export NDKROOT=$ANDROID_NDK
        export NDK_MODULE_PATH=$ANDROID_NDK
    fi

    export GOPATH=$HOME/Projects/Go
}

__bashrc_main "$@"
unset __bashrc_main
