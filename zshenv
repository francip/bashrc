# zshenv — sourced for ALL zsh invocations (interactive, non-interactive,
# login, non-login). Delegates to ~/src/bashrc/shenv for the actual work.
#
# Why this matters: ~/.zshrc is NOT sourced for non-interactive zsh, so
# `ssh host 'cmd'` only sees what zshenv sets up. Putting PATH, nvm, conda,
# ssh-agent etc. in shenv means all those non-interactive contexts (scp,
# remote git, cron-from-ssh, VS Code's git, etc.) work correctly.
#
# Anything interactive (prompt, aliases, completion, MOTD) belongs in
# ~/.zshrc, NOT here.

__zshenv_main() {
    local SH_SOURCE_FILE SH_SOURCE_DIR

    SH_SOURCE_FILE=${(%):-%x}
    while [[ -L "$SH_SOURCE_FILE" ]]; do
        SH_SOURCE_FILE=$(readlink "$SH_SOURCE_FILE")
    done

    SH_SOURCE_DIR=$(dirname "$SH_SOURCE_FILE")
    SH_SOURCE_DIR=$(
        cd "$SH_SOURCE_DIR" >/dev/null
        pwd
    )

    if [[ -f "$SH_SOURCE_DIR/shenv" ]]; then
        . "$SH_SOURCE_DIR/shenv"
    fi
}

__zshenv_main "$@"
unset -f __zshenv_main
