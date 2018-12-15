#!/bin/bash

__ln_test_main () {
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

    local TEMFILE
    TEMPFILE=$TMPDIR/$RANDOM
    if ln -s $BASH_SOURCE_DIR/$BASH_SOURCE_FILE $TEMPFILE >/dev/null 2>&1; then
        rm $TEMPFILE
        echo -e $COLOR_GREEN'Success'$COLOR_NONE
    else
        echo -e $COLOR_RED'Fail'$COLOR_NONE
        echo -e $COLOR_YELLOW'Note:'$COLOR_NONE' Run Msys as administrator to create file links under Msys.'$COLOR_NONE
    fi
}

__ln_test_main "$@"
unset __ln_test_main
