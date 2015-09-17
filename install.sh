#!/bin/bash

__install_main() {
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
        __get_install_dir() {
          echo $BASH_SOURCE_DIR
        }
        __get_install_file() {
          echo $BASH_SOURCE_FILE
        }
EOF
)"

    local BASH_COLOR_DEFS
    if [[ -e ~/.configure_colors ]]; then
        BASH_COLOR_DEFS=`cat ~/.configure_colors`
    elif [[ -e $BASH_SOURCE_DIR/configure_colors ]]; then
        BASH_COLOR_DEFS=`cat $BASH_SOURCE_DIR/configure_colors`
    fi

    local BASH_OS_DEFS
    if [[ -e ~/.configure_os ]]; then
        BASH_OS_DEFS=`cat ~/.configure_os`
    elif [[ -e $BASH_SOURCE_DIR/configure_os ]]; then
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

    local OS_TYPE_SUFFIX OS_DISTRO_SUFFIX OS_RELEASE_SUFFIX

    OS_TYPE_SUFFIX=`echo $BASH_OS_TYPE | tr '[A-Z]' '[a-z]'`
    OS_DISTRO_SUFFIX=`echo $BASH_OS_DISTRO | tr '[A-Z]' '[a-z]'`
    OS_RELEASE_SUFFIX=`echo $BASH_OS_DISTRO | tr '[A-Z]' '[a-z]'`

    local FILES CURRENT_FILE TARGET_FILE SOURCE_FILE

    FILES=( bash_profile bashrc inputrc bash_logout configure_colors configure_os vimrc )
    for CURRENT_FILE in ${FILES[@]}; do
        if [[ -e ~/.$CURRENT_FILE ]]; then
            if [[ ! -L ~/.$CURRENT_FILE ]]; then
                echo -e $COLOR_YELLOW_BOLD'~/.'$CURRENT_FILE$COLOR_NONE' exists. Skipping symbolic link to '$COLOR_CYAN_BOLD$BASH_SOURCE_DIR'/'$CURRENT_FILE$COLOR_NONE
            else
                TARGET_FILE=~/.$CURRENT_FILE
                while [[ -L "$TARGET_FILE" ]]; do
                    TARGET_FILE=$(readlink "$TARGET_FILE")
                done
                echo -e $COLOR_YELLOW_BOLD'~/.'$CURRENT_FILE$COLOR_NONE' exists and points to '$COLOR_CYAN_BOLD$TARGET_FILE$COLOR_NONE'. Skipping symbolic link to '$COLOR_CYAN_BOLD$BASH_SOURCE_DIR'/'$CURRENT_FILE$COLOR_NONE
            fi
        else
            SOURCE_FILE=$BASH_SOURCE_DIR/$CURRENT_FILE
            if [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX'_'$OS_RELEASE_SUFFIX ]]; then
                SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX'_'$OS_RELEASE_SUFFIX
            elif [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX ]]; then
                SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX
            elif [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX ]]; then
                SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX
            fi
            if [[ -f $SOURCE_FILE ]]; then
                echo -e 'Installing symbolic link from '$COLOR_GREEN_BOLD'~/.'$CURRENT_FILE$COLOR_NONE' to '$COLOR_CYAN_BOLD$SOURCE_FILE$COLOR_NONE
                ln -s $SOURCE_FILE ~/.$CURRENT_FILE
            else
                echo -e 'File '$COLOR_RED_BOLD$SOURCE_FILE$COLOR_NONE' does not exist. Cannot install symbolic link from '$COLOR_GREEN_BOLD'~/.'$CURRENT_FILE$COLOR_NONE
            fi
        fi
    done
}

__install_main "$@"
unset __install_main

