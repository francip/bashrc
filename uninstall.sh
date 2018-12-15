#!/bin/bash

__uninstall_main () {
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

    local FILES CURRENT_FILE SOURCE_FILE LINK_FILE

    FILES=( bash_profile bashrc inputrc bash_logout configure_colors configure_os vimrc tmux.conf )
    for CURRENT_FILE in "${FILES[@]}"; do
        SOURCE_FILE=$BASH_SOURCE_DIR/$CURRENT_FILE
        if [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX'_'$OS_RELEASE_SUFFIX ]]; then
            SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX'_'$OS_RELEASE_SUFFIX
        elif [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX ]]; then
            SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX
        elif [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX ]]; then
            SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX
        fi

        LINK_FILE=$HOME/.$CURRENT_FILE

        if [[ -e "$LINK_FILE" ]]; then
            if [[ -L "$LINK_FILE" ]]; then

                local LINK_TARGET_FILE

                LINK_TARGET_FILE=$LINK_FILE
                while [[ -L "$LINK_TARGET_FILE" ]]; do
                    LINK_TARGET_FILE=$(readlink "$LINK_TARGET_FILE")
                done

                if [[ "$LINK_TARGET_FILE" == "$SOURCE_FILE" ]]; then
                    echo -e $COLOR_GREEN_BOLD$LINK_FILE$COLOR_NONE': Removed, was linked to '$COLOR_CYAN_BOLD$SOURCE_FILE$COLOR_NONE
                    rm "$LINK_FILE"
                else
                    echo -e $COLOR_YELLOW_BOLD$LINK_FILE$COLOR_NONE': Not removing, points to '$COLOR_YELLOW_BOLD$LINK_TARGET_FILE$COLOR_NONE' instead of '$COLOR_CYAN_BOLD$SOURCE_FILE$COLOR_NONE
                fi
            else
                echo -e $COLOR_YELLOW_BOLD$LINK_FILE$COLOR_NONE': Not removing, not a symbolic link'
            fi
        else
            echo -e $COLOR_RED_BOLD$LINK_FILE$COLOR_NONE': Not removing, does not exist'
        fi
    done
}

__uninstall_main "$@"
unset __uninstall_main
