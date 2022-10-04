# This file is not intended for direct execution
if [ -n "$ZSH_VERSION" ]; then
    case $ZSH_EVAL_CONTEXT in
    *file)
        ;;
    *file:cmdsubst)
        ;;
    *)
        echo 'This script is not intended for direct Zsh execution'
        exit
        ;;
    esac
elif [ -n "$BASH_VERSION" ]; then
    if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
        echo 'This script is not intended for direct bash execution'
        exit
    fi
else
    # Only Zsh and Bash supported
    echo 'This script requires Zsh or Bash'
    exit
fi

__direct_test_main() {
    eval "$(__sh_color_definitions)"
    eval "$(__sh_os_definitions)"

    echo -e $COLOR_GREEN'Success'$COLOR_NONE
}

__direct_test_main "$@"
unset -f __direct_test_main
