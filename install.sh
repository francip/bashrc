#!/usr/bin/env bash

__install_main() {
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

    if [[ $BASH_OS_TYPE == Windows ]]; then
        if [[ $BASH_OS_DISTRO == Msys ]]; then
            if [[ "$MSYS" == "winsymlinks:nativestrict" ]]; then
                echo
            else
                echo
                echo -e $COLOR_YELLOW_BOLD'WARNING:'$COLOR_NONE' Set '$COLOR_CYAN_BOLD'MSYS=winsymlinks:nativestrict'$COLOR_NONE' in your Windows environment,'
                echo -e 'then rerun the installer in a new Bash window as administrator.'
                echo
                exit
            fi

            local TEMFILE
            TEMPFILE=$TMPDIR/$RANDOM
            if ln -s $BASH_SOURCE_DIR/$BASH_SOURCE_FILE $TEMPFILE >/dev/null 2>&1; then
                rm $TEMPFILE
            else
                echo -e $COLOR_YELLOW'WARNING:'$COLOR_NONE' Open new Bash windows as administrator, set '$COLOR_CYAN'export HOME='$HOME$COLOR_NONE
                echo -e 'and rerun the installer.'
                echo
                exit
            fi
        else
            echo
            echo -e $COLOR_RED_BOLD'WARNING:'$COLOR_NONE' Unsupported Windows environment.'
            echo
            exit
        fi
    fi

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
            if [[ ! -L "$LINK_FILE" ]]; then
                echo -e $COLOR_YELLOW_BOLD$LINK_FILE$COLOR_NONE': Exists and cannot be linked to '$COLOR_CYAN_BOLD$SOURCE_FILE$COLOR_NONE
            else
                local LINK_TARGET_FILE

                LINK_TARGET_FILE=$LINK_FILE
                while [[ -L "$LINK_TARGET_FILE" ]]; do
                    LINK_TARGET_FILE=$(readlink "$LINK_TARGET_FILE")
                done

                if [[ "$LINK_TARGET_FILE" == "$SOURCE_FILE" ]]; then
                    echo -e $COLOR_GREEN_BOLD$LINK_FILE$COLOR_NONE': Already linked and points to '$COLOR_CYAN_BOLD$SOURCE_FILE$COLOR_NONE
                else
                    echo -e $COLOR_YELLOW_BOLD$LINK_FILE$COLOR_NONE': Already linked but points to '$COLOR_YELLOW_BOLD$LINK_TARGET_FILE$COLOR_NONE' instead of '$COLOR_CYAN_BOLD$SOURCE_FILE$COLOR_NONE
                fi
            fi
        else
            if [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX'_'$OS_RELEASE_SUFFIX ]]; then
                SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX'_'$OS_RELEASE_SUFFIX
            elif [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX ]]; then
                SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX'_'$OS_DISTRO_SUFFIX
            elif [[ -e $SOURCE_FILE'_'$OS_TYPE_SUFFIX ]]; then
                SOURCE_FILE=$SOURCE_FILE'_'$OS_TYPE_SUFFIX
            fi
            if [[ -f "$SOURCE_FILE" ]]; then
                echo -e $COLOR_GREEN_BOLD$LINK_FILE$COLOR_NONE': Created as a symbolic link and points to '$COLOR_CYAN_BOLD$SOURCE_FILE$COLOR_NONE
                ln -s "$SOURCE_FILE" "$LINK_FILE"
            else
                echo -e $COLOR_RED_BOLD$LINK_FILE$COLOR_NONE': Cannot be linked to non-existing '$COLOR_RED_BOLD$SOURCE_FILE$COLOR_NONE
            fi
        fi
    done
}

__install_main "$@"
unset __install_main
