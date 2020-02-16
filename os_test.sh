__os_test_main() {

    eval "$(__sh_color_definitions)"
    eval "$(__sh_os_definitions)"

    echo -e 'Type    : '$COLOR_GREEN$SH_OS_TYPE$COLOR_NONE
    echo -e 'Distro  : '$COLOR_GREEN$SH_OS_DISTRO$COLOR_NONE
    echo -e 'Release : '$COLOR_GREEN$SH_OS_RELEASE$COLOR_NONE
}

__os_test_main "$@"
unset -f __os_test_main
