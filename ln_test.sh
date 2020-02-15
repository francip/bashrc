__ln_test_main() {
    eval "$(__sh_color_definitions)"
    eval "$(__sh_os_definitions)"

    # local SH_SOURCE_DIR=$(__get_sh_scripts_dir)
    # local SH_SOURCE_FILE=$(__get_sh_scripts_file)

    # . $SH_SOURCE_DIR/direct_test.sh

    local TEMFILE
    TEMPFILE=${TMPDIR:-/tmp}/$RANDOM
    if ln -s $SH_SOURCE_DIR/$SH_SOURCE_FILE $TEMPFILE >/dev/null 2>&1; then
        rm $TEMPFILE
        echo -e $COLOR_GREEN'Success'$COLOR_NONE
    else
        echo -e $COLOR_RED'Fail'$COLOR_NONE
        echo -e $COLOR_YELLOW'Note:'$COLOR_NONE' Run Msys as administrator to create file links under Msys.'$COLOR_NONE
    fi
}

__ln_test_main "$@"
unset -f __ln_test_main
