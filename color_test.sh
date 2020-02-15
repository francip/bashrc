__color_test_main() {
    local SH_SOURCE_FILE SH_SOURCE_DIR SH_SOURCE_FILE_ESCAPED

    if [ -n "$ZSH_VERSION" ]; then
        SH_SOURCE_FILE=${(%):-%x}
    elif [ -n "$BASH_VERSION" ]; then
        SH_SOURCE_FILE=${BASH_SOURCE[0]}
    fi

    while [ -L "$SH_SOURCE_FILE" ]; do
        SH_SOURCE_FILE=$(readlink "$SH_SOURCE_FILE")
    done

    SH_SOURCE_DIR=$(dirname "$SH_SOURCE_FILE")
    SH_SOURCE_DIR=`cd "$SH_SOURCE_DIR" >/dev/null; pwd`
    SH_SOURCE_FILE=$(basename "$SH_SOURCE_FILE")
    SH_SOURCE_FILE_ESCAPED=${SH_SOURCE_FILE/\\ /_/}

    # SH_SOURCE_DIR is a full path to the location of this script

    eval "$(cat <<EOF
        __get_${SH_SOURCE_FILE_ESCAPED}_dir() {
          echo $SH_SOURCE_DIR
        }
        __get_${SH_SOURCE_FILE_ESCAPED}_file() {
          echo $SH_SOURCE_FILE
        }
EOF
)"

    local SH_COLOR_DEFS
    if [[ -e "$SH_SOURCE_DIR/configure_colors" ]]; then
        SH_COLOR_DEFS=`cat "$SH_SOURCE_DIR/configure_colors"`
    fi

    local SH_OS_DEFS
    if [[ -e "$SH_SOURCE_DIR/configure_os" ]]; then
        SH_OS_DEFS=`cat "$SH_SOURCE_DIR/configure_os"`
    fi

    eval "$(cat <<EOF
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

    echo -e $COLOR_RED               'Red              '$COLOR_NONE
    echo -e $COLOR_GREEN             'Green            '$COLOR_NONE
    echo -e $COLOR_YELLOW            'Yellow           '$COLOR_NONE
    echo -e $COLOR_BLUE              'Blue             '$COLOR_NONE
    echo -e $COLOR_MAGENTA           'Magenta          '$COLOR_NONE
    echo -e $COLOR_CYAN              'Cyan             '$COLOR_NONE
    echo -e $COLOR_WHITE             'White            '$COLOR_NONE
    echo -e $COLOR_NONE              'None             '$COLOR_NONE

    echo -e $COLOR_RED_BOLD          'Red bold         '$COLOR_NONE
    echo -e $COLOR_GREEN_BOLD        'Green bold       '$COLOR_NONE
    echo -e $COLOR_YELLOW_BOLD       'Yellow bold      '$COLOR_NONE
    echo -e $COLOR_BLUE_BOLD         'Blue bold        '$COLOR_NONE
    echo -e $COLOR_MAGENTA_BOLD      'Magenta bold     '$COLOR_NONE
    echo -e $COLOR_CYAN_BOLD         'Cyan bold        '$COLOR_NONE
    echo -e $COLOR_WHITE_BOLD        'White bold       '$COLOR_NONE
    echo -e $COLOR_BOLD              'Bold             '$COLOR_NONE

    echo -e $COLOR_RED_UNDERLINE     'Red underline    '$COLOR_NONE
    echo -e $COLOR_GREEN_UNDERLINE   'Green underline  '$COLOR_NONE
    echo -e $COLOR_YELLOW_UNDERLINE  'Yellow underline '$COLOR_NONE
    echo -e $COLOR_BLUE_UNDERLINE    'Blue underline   '$COLOR_NONE
    echo -e $COLOR_MAGENTA_UNDERLINE 'Magenta underline'$COLOR_NONE
    echo -e $COLOR_CYAN_UNDERLINE    'Cyan underline   '$COLOR_NONE
    echo -e $COLOR_WHITE_UNDERLINE   'White underline  '$COLOR_NONE
    echo -e $COLOR_UNDERLINE         'Underline        '$COLOR_NONE

    echo -e $COLOR_RED_INVERT        'Red invert       '$COLOR_NONE
    echo -e $COLOR_GREEN_INVERT      'Green invert     '$COLOR_NONE
    echo -e $COLOR_YELLOW_INVERT     'Yellow invert    '$COLOR_NONE
    echo -e $COLOR_BLUE_INVERT       'Blue invert      '$COLOR_NONE
    echo -e $COLOR_MAGENTA_INVERT    'Magenta invert   '$COLOR_NONE
    echo -e $COLOR_CYAN_INVERT       'Cyan invert      '$COLOR_NONE
    echo -e $COLOR_WHITE_INVERT      'White invert     '$COLOR_NONE
    echo -e $COLOR_INVERT            'Invert           '$COLOR_NONE
}

__color_test_main "$@"
unset -f __color_test_main
