__color_test_main() {
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
