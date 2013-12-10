#!/bin/bash

__main() {
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
        __get_${BASH_SOURCE_FILE}_dir() {
          echo $BASH_SOURCE_DIR
        }
        __get_${BASH_SOURCE_FILE}_file() {
          echo $BASH_SOURCE_FILE
        }
EOF
)"

    #__get_${BASH_SOURCE_FILE}_file
    #__get_${BASH_SOURCE_FILE}_dir
}

__main "$@"
unset __main
