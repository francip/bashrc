#!/bin/bash

__color_test_main() {
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

}

__install_main "$@"SH_INTERACTIVE ] && echo -e $COLOR_RED               'Red              '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_GREEN             'Green            '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_YELLOW            'Yellow           '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_BLUE              'Blue             '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_MAGENTA           'Magenta          '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_CYAN              'Cyan             '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_WHITE             'White            '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_NONE              'None             '$COLOR_NONE

    [ $BASH_INTERACTIVE ] && echo -e $COLOR_RED_BOLD          'Red bold         '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_GREEN_BOLD        'Green bold       '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_YELLOW_BOLD       'Yellow bold      '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_BLUE_BOLD         'Blue bold        '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_MAGENTA_BOLD      'Magenta bold     '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_CYAN_BOLD         'Cyan bold        '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_WHITE_BOLD        'White bold       '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_BOLD              'Bold             '$COLOR_NONE

    [ $BASH_INTERACTIVE ] && echo -e $COLOR_RED_UNDERLINE     'Red underline    '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_GREEN_UNDERLINE   'Green underline  '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_YELLOW_UNDERLINE  'Yellow underline '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_BLUE_UNDERLINE    'Blue underline   '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_MAGENTA_UNDERLINE 'Magenta underline'$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_CYAN_UNDERLINE    'Cyan underline   '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_WHITE_UNDERLINE   'White underline  '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_UNDERLINE         'Underline        '$COLOR_NONE

    [ $BASH_INTERACTIVE ] && echo -e $COLOR_RED_INVERT        'Red invert       '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_GREEN_INVERT      'Green invert     '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_YELLOW_INVERT     'Yellow invert    '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_BLUE_INVERT       'Blue invert      '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_MAGENTA_INVERT    'Magenta invert   '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_CYAN_INVERT       'Cyan invert      '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_WHITE_INVERT      'White invert     '$COLOR_NONE
    [ $BASH_INTERACTIVE ] && echo -e $COLOR_INVERT            'Invert           '$COLOR_NONE

unset __install_main

