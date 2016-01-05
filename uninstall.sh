#!/bin/bash

__uninstall_main() {
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
        __get_uninstall_dir() {
          echo $BASH_SOURCE_DIR
        }
        __get_uninstall_file() {
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

    local FILES CURRENT_FILE TARGET_FILE

    FILES=( bash_profile bashrc inputrc bash_logout configure_colors configure_os vimrc )
    for CURRENT_FILE in ${FILES[@]}; do
        if [[ -L ~/.$CURRENT_FILE ]]; then
            TARGET_FILE=~/.$CURRENT_FILE
            while [[ -L "$TARGET_FILE" ]]; do
                TARGET_FILE=$(readlink "$TARGET_FILE")
            done
            echo -e 'Removing '$COLOR_RED_BOLD'~/.'$CURRENT_FILE$COLOR_NONE' linked to '$COLOR_CYAN_BOLD$TARGET_FILE$COLOR_NONE
            rm ~/.$CURRENT_FILE
        else
            if [[ -e ~/.$CURRENT_FILE ]]; then
                echo -e $COLOR_YELLOW_BOLD'~/.'$CURRENT_FILE$COLOR_NONE' exists and is not a symbolic link. Will not remove.'
            else
                echo -e $COLOR_YELLOW_BOLD'~/.'$CURRENT_FILE$COLOR_NONE' does not exist. Nothing to remove.'
            fi
        fi
    done
}

__uninstall_main "$@"
unset __uninstall_main

