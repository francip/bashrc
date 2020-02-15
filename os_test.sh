__os_test_main() {
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

    echo -e 'Type    : '$COLOR_GREEN$SH_OS_TYPE$COLOR_NONE
    echo -e 'Distro  : '$COLOR_GREEN$SH_OS_DISTRO$COLOR_NONE
    echo -e 'Release : '$COLOR_GREEN$SH_OS_RELEASE$COLOR_NONE
}

__os_test_main "$@"
unset -f __os_test_main
