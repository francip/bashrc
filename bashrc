# Source common definitions

__bashrc_main() {
    local SH_SOURCE_FILE SH_SOURCE_DIR

    SH_SOURCE_FILE=${BASH_SOURCE[0]}
    while [[ -L "$SH_SOURCE_FILE" ]]; do
        SH_SOURCE_FILE=$(readlink "$SH_SOURCE_FILE")
    done

    SH_SOURCE_DIR=$(dirname "$SH_SOURCE_FILE")
    SH_SOURCE_DIR=$(
        cd "$SH_SOURCE_DIR" >/dev/null
        pwd
    )

    # Source shared env (idempotent — short-circuits if bashenv already loaded
    # it). Sets SH_OS_*, BREW_DIR exported globally. Defines __add_to_path,
    # __include_files, __sh_color_definitions, ... globally. Configures PATH,
    # nvm, conda, ssh-agent discovery, etc.
    if [[ -f "$SH_SOURCE_DIR/shenv" ]]; then
        . "$SH_SOURCE_DIR/shenv"
    fi

    # Pull COLOR_* into local scope for prompt/banner use (shenv defines the
    # function globally; configure_colors uses 'local' so we re-eval here)
    if [[ -n $(type -t __sh_color_definitions) ]]; then
        eval "$(__sh_color_definitions)"
    fi

    local SH_INTERACTIVE

    case $- in
    *i*)
        SH_INTERACTIVE=1
        ;;
    esac

    # Windows OpenSSH doesn't pass SSH env vars into WSL; import them
    if [[ $SH_OS_FLAVOR == WSL && -z $SSH_CONNECTION ]]; then
        local _win_ssh
        _win_ssh=$(cmd.exe /c "echo %SSH_CONNECTION%" 2>/dev/null | tr -d '\r\n')
        if [[ -n "$_win_ssh" && "$_win_ssh" != "%SSH_CONNECTION%" ]]; then
            export SSH_CONNECTION="$_win_ssh"
            _win_ssh=$(cmd.exe /c "echo %SSH_CLIENT%" 2>/dev/null | tr -d '\r\n')
            [[ -n "$_win_ssh" && "$_win_ssh" != "%SSH_CLIENT%" ]] && export SSH_CLIENT="$_win_ssh"
        fi
        unset _win_ssh
    fi

    # When SSHing into Windows OpenSSH with WSL as shell, start in home dir
    if [[ $SH_OS_FLAVOR == WSL && -n $SSH_CONNECTION && $PWD == /mnt/[cC]/* ]]; then
        cd ~
    fi

    # Ghostty terminfo fallback (must be before tmux auto-attach)
    if [[ "$TERM" == "xterm-ghostty" ]]; then
        if ! infocmp xterm-ghostty >/dev/null 2>&1; then
            export TERM=xterm-256color
        fi
    fi

    # Show MOTD on SSH login (Linux; inside tmux the pre-attach output is lost)
    if [[ $SH_INTERACTIVE && -n $SSH_CONNECTION && $SH_OS_TYPE == Linux && -f /run/motd.dynamic && -z $MOTD_SHOWN ]]; then
        export MOTD_SHOWN=1
        cat /run/motd.dynamic
    fi

    [[ $SH_INTERACTIVE ]] && echo
    [[ $SH_INTERACTIVE ]] && echo -e 'Configuring environment for '$COLOR_GREEN_BOLD'Bash '$COLOR_YELLOW_BOLD${BASH_VERSINFO[0]}'.'${BASH_VERSINFO[1]}'.'${BASH_VERSINFO[2]}$COLOR_NONE' on '$COLOR_GREEN_BOLD$SH_OS_DISTRO$COLOR_NONE' '$COLOR_YELLOW_BOLD$SH_OS_RELEASE$COLOR_NONE' ('$COLOR_GREEN_BOLD$SH_OS_TYPE$COLOR_NONE')'

    if [ -z "$BREW_DIR" ]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e $COLOR_GREEN_BOLD'Homebrew'$COLOR_NONE' not installed'
    else
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e $COLOR_GREEN_BOLD'Homebrew'$COLOR_NONE' installed at '$COLOR_YELLOW_BOLD$BREW_DIR$COLOR_NONE
    fi

    # SSH configuration (must run before tmux auto-attach so the agent
    # environment is inherited by the tmux session). shenv did initial socket
    # discovery; here we handle re-discovery (path changes after sleep/wake)
    # and starting an agent if none exists (interactive only).
    if [[ $SH_OS_TYPE == Windows ]]; then
        # Use Windows native OpenSSH so that ssh/scp/ssh-add talk to the
        # Windows ssh-agent service instead of a standalone Git Bash agent.
        # WIN_OPENSSH_DIR is set by shrc.cmd; fall back to the well-known path.
        local _win_ssh_dir="${WIN_OPENSSH_DIR:-/c/Windows/System32/OpenSSH}"
        _win_ssh_dir="${_win_ssh_dir//\\//}"          # backslash → forward slash
        [[ $_win_ssh_dir != /* ]] && _win_ssh_dir="/c${_win_ssh_dir#C:}"  # C:\… → /c/…
        if [[ -x "$_win_ssh_dir/ssh.exe" ]]; then
            # Shell functions override PATH, so Git Bash's /usr/bin/ssh is bypassed.
            # Use eval to bake the resolved path into the function bodies,
            # since _win_ssh_dir is local and will be gone after this function exits.
            eval "ssh()     { \"$_win_ssh_dir/ssh.exe\" \"\$@\"; }"
            eval "ssh-add() { \"$_win_ssh_dir/ssh-add.exe\" \"\$@\"; }"
            eval "scp()     { \"$_win_ssh_dir/scp.exe\" \"\$@\"; }"
            eval "sftp()    { \"$_win_ssh_dir/sftp.exe\" \"\$@\"; }"
            export -f ssh ssh-add scp sftp
            export GIT_SSH="$_win_ssh_dir/ssh.exe"
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Using Windows native '$COLOR_GREEN_BOLD'OpenSSH'$COLOR_NONE' + '$COLOR_GREEN_BOLD'ssh-agent'$COLOR_NONE
        else
            export SSH_AUTH_SOCK=/tmp/.ssh-socket
            ssh-add -l >/dev/null 2>&1
            if [[ $? = 2 ]]; then
                [[ $SH_INTERACTIVE ]] && echo
                [[ $SH_INTERACTIVE ]] && echo -e 'Creating new ssh-agent'
                rm -f /tmp/.ssh-script /tmp/.ssh-agent-pid /tmp/.ssh-socket
                ssh-agent -a $SSH_AUTH_SOCK >/tmp/.ssh-script
                . /tmp/.ssh-script
                [[ $SH_INTERACTIVE ]] && echo $SSH_AGENT_PID >/tmp/.ssh-agent-pid
            fi
        fi
    fi

    if [[ $SH_OS_TYPE == OSX ]]; then
        # Re-discover the launchd-managed socket (path changes each boot
        # and after sleep/wake; shenv only ran once at shell startup)
        if [[ -z $SSH_AUTH_SOCK || ! -S $SSH_AUTH_SOCK ]]; then
            local _mac_sock
            # macOS 26+ moved sockets from /private/tmp to /var/run
            _mac_sock=$(find /private/tmp /var/run -path "*/com.apple.launchd.*/Listeners" -user $USER 2>/dev/null | head -1)
            if [[ -S "$_mac_sock" ]]; then
                export SSH_AUTH_SOCK="$_mac_sock"
            fi
        fi
    fi

    if [[ $SH_OS_TYPE == Linux && -z $TMUX ]]; then
        # Skip inside tmux; agent env vars are inherited from the pre-tmux shell
        local _ssh_sock
        _ssh_sock=$(find /tmp/ssh-* -name agent.\* 2>/dev/null | head -1)
        if [[ -n "$(pgrep -u $USER ssh-agent)" && -S "$_ssh_sock" ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'SSH agent '$COLOR_GREEN_BOLD'running'$COLOR_NONE'. Connecting...'
            export SSH_AGENT_PID=$(pgrep -n -u $USER ssh-agent)
            export SSH_AUTH_SOCK="$_ssh_sock"
        elif [[ $SH_INTERACTIVE ]]; then
            # Only kill/restart in interactive shells — non-interactive shells
            # (scp, remote git, cron) must not disrupt running agents
            echo
            echo -e 'SSH agent '$COLOR_YELLOW_BOLD'not running'$COLOR_NONE'. Starting new one...'
            pkill -u $USER ssh-agent 2>/dev/null
            rm -rf /tmp/ssh-* 2>/dev/null
            eval $(ssh-agent -s) >/dev/null
        fi
    fi

    # Auto-attach to tmux on SSH login (before heavy init — tmux spawns a fresh shell).
    # TMUX_AUTO_ATTACH=0 disables it.
    # TMUX_AUTO_ATTACH_SESSION changes the base session (default: main).
    # TMUX_AUTO_ATTACH_MODE=shared|auto|dedicated controls session sharing.
    if [[ -n $SSH_CONNECTION && -z $TMUX && $- == *i* && $TMUX_AUTO_ATTACH != 0 ]]; then
        if command -v tmux >/dev/null 2>&1; then
            TMUX_ATTACH_SESSION=$(__tmux_auto_attach_target_session)
            exec tmux new-session -As "$TMUX_ATTACH_SESSION"
        fi
    fi

    # Non-interactive shells have nothing more to do — env was set up by
    # shenv, and everything below is interactive-only (prompt, completion,
    # aliases, _local hooks, banners).
    if [[ ! $SH_INTERACTIVE ]]; then
        return
    fi

    HISTSIZE=10000
    HISTFILESIZE=10000

    # Source additional global, local, and personal definitions
    echo
    __include_files "${HOME}/.bashrc.local" "${HOME}/.bashrc_local" "${SH_SOURCE_DIR}/aliases" "${HOME}/.aliases.local" "${HOME}/.aliases_local"

    # ITerm2 integration
    local ITERM2_INTEGRATION
    if [[ $SH_OS_TYPE == OSX ]]; then
        ITERM2_INTEGRATION=$HOME/.iterm2_shell_integration.bash
        if [[ -f "$ITERM2_INTEGRATION" ]]; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD$ITERM2_INTEGRATION$COLOR_NONE
            . "$ITERM2_INTEGRATION"
        fi
    fi

    # Bash completion
    local BASH_COMPLETION_INSTALLED BASH_COMPLETION_INSTALLED_COMMAND
    if [[ $SH_OS_TYPE == OSX ]]; then
        BASH_COMPLETION_INSTALLED_COMMAND=_brew_completions
    elif [[ $SH_OS_TYPE == Linux ]]; then
        BASH_COMPLETION_INSTALLED_COMMAND=_init_completion
    fi
    BASH_COMPLETION_INSTALLED=$(type -t ${BASH_COMPLETION_INSTALLED_COMMAND})

    if [[ -z $BASH_COMPLETION && -z $BASH_COMPLETION_INSTALLED ]]; then
        if [[ $SH_OS_TYPE == OSX ]]; then
            # Bash completion for Mac OS X (from Homebrew or MacPorts)
            if [[ -f /usr/local/etc/bash_completion ]]; then
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD'/usr/local/etc/bash_completion'$COLOR_NONE
                . /usr/local/etc/bash_completion
            elif [[ -f /opt/local/etc/profile.d/bash_completion.sh ]]; then
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD'/opt/local/etc/profile.d/bash_completion.sh'$COLOR_NONE
                . /opt/local/etc/profile.d/bash_completion.sh
            elif [[ -f ${BREW_DIR}/bin/brew ]]; then
                if [[ -f ${BREW_DIR}/etc/profile.d/bash_completion.sh ]]; then
                    [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD$BREW_DIR'/etc/profile.d/bash_completion.sh'$COLOR_NONE
                    . ${BREW_DIR}/etc/profile.d/bash_completion.sh
                fi
            fi
        elif [[ $SH_OS_TYPE == Linux ]]; then
            # Bash completion for Linux
            if [[ -f /etc/bash_completion ]]; then
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD'/etc/bash_completion'$COLOR_NONE
                . /etc/bash_completion
            fi
        fi

        BASH_COMPLETION_INSTALLED=$(type -t ${BASH_COMPLETION_INSTALLED_COMMAND})

        if [[ -z $BASH_COMPLETION && -z $BASH_COMPLETION_INSTALLED ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Bash completion '$COLOR_RED_BOLD'not configured'$COLOR_NONE
        fi
    fi

    # Git completion and prompt
    local GIT_COMPLETION
    if [[ -z $(type -t __git_ps1) ]]; then
        GIT_COMPLETION=$(type -P git-completion.bash)

        if [[ -z $GIT_COMPLETION ]]; then
            GIT_COMPLETION=$HOME/bin/git-completion.bash
        fi

        if [[ -f "$GIT_COMPLETION" ]]; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD$GIT_COMPLETION$COLOR_NONE
            . "$GIT_COMPLETION"
        fi
    fi

    if [[ -z $(type -t __git_ps1) ]]; then
        if [[ -f /opt/homebrew/etc/bash_completion.d/git-prompt.sh ]]; then
            . /opt/homebrew/etc/bash_completion.d/git-prompt.sh
        fi
    fi

    # ADB completion
    local ADB_COMPLETION
    ADB_COMPLETION=$(type -P adb.bash)
    if [[ -z $ADB_COMPLETION ]]; then
        ADB_COMPLETION=$HOME/bin/adb.bash
    fi

    if [[ -f "$ADB_COMPLETION" ]]; then
        [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD$ADB_COMPLETION$COLOR_NONE
        . "$ADB_COMPLETION"
    fi

    # NVM completion (env loaded nvm.sh; this is the interactive completion)
    if [[ -d $NVM_DIR && -s "$NVM_DIR/bash_completion" ]]; then
        . "$NVM_DIR/bash_completion"
    fi

    if [[ -n $BASH_COMPLETION_INSTALLED ]]; then
        # Affects cd behavior
        __add_to_cd_path "." "${HOME}" "${HOME}/src"
    fi

    # SSH client
    if [[ -n $SSH_CLIENT ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Connected from '$COLOR_YELLOW_BOLD$(get_ssh_client_ip)$COLOR_NONE

        if is_tailscale_ssh; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Connection via '$COLOR_GREEN_BOLD'Tailscale'$COLOR_NONE
        fi

        if [[ $SH_INTERACTIVE && $SH_OS_TYPE == OSX ]]; then
            echo -e 'Unlocking '$COLOR_CYAN_BOLD'keychain'$COLOR_NONE'...'
            security unlock-keychain
        fi
    fi

    # Prompt
    local COLOR_ROOT_INVERT VERSION_CONTROL_PROMPT

    COLOR_ROOT_INVERT=$COLOR_GREEN_INVERT
    if [[ "$(whoami)" == "root" ]]; then
        COLOR_ROOT_INVERT=$COLOR_RED_INVERT
    fi

    # Show git branch in prompt
    __version_control_ps1() {
        if [[ -n $(type -t __git_ps1) ]]; then
            __git_ps1 '[git %s] '
        else
            local branch
            branch=$(git symbolic-ref --short HEAD 2>/dev/null)
            [[ -n "$branch" ]] && printf '[git %s] ' "$branch"
        fi
    }

    VERSION_CONTROL_PROMPT='$(__version_control_ps1)'

    export PS1='\['$COLOR_BOLD'\]\['$COLOR_ROOT_INVERT'\]\u\['$COLOR_NONE'\] \['$COLOR_BOLD'\]\['$COLOR_YELLOW_INVERT'\]\h\['$COLOR_NONE'\] \['$COLOR_CYAN_BOLD'\]\w\['$COLOR_NONE'\] \['$COLOR_MAGENTA_BOLD'\]'$VERSION_CONTROL_PROMPT'\['$COLOR_NONE'\]\$ '

    # Color directories
    if [[ $SH_OS_TYPE == OSX ]]; then
        # Mac OS X settings
        #export CLICOLOR=1
        export LSCOLORS=GxFxCxDxBxegedabagaced
    fi

    if [[ $SH_OS_TYPE == Linux ]]; then
        # Linux settings
        export LS_COLORS='di=01;36'
    fi

    # Misc declarations
    if [[ $SH_OS_TYPE == Linux ]]; then
        if [[ $SH_OS_DISTRO == Ubuntu ]]; then
            if [[ -z $SHELL ]]; then
                # Ubuntu does not always define it for some reason
                export SHELL=/usr/bin/env bash
            fi
        fi
    fi

    # Local declarations
    if [[ -n $(type -t __bashrc_local_run) ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Executing '$COLOR_YELLOW_BOLD$(__bashrc_local)$COLOR_NONE

        __bashrc_local_run "$@"
    fi

    # Global aliases deferred load
    if [[ -n $(type -t __aliases_load) ]]; then
        __aliases_load "$@"
    fi

    # Local aliases deferred load
    if [[ -n $(type -t __aliases_local_load) ]]; then
        __aliases_local_load "$@"
    fi

    # Node
    # After local dotrc to ensure we don't pick accidentally local dotrc node version
    if [[ -d $NVM_DIR ]]; then
        if [[ $(nvm current) == system ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Switching node from '$COLOR_YELLOW_BOLD'system'$COLOR_NONE' to '$COLOR_YELLOW_BOLD'nvm default'$COLOR_NONE

            nvm use default
        fi
    fi

    # Free space
    local FREE_SPACE FREE_SPACE_READABLE
    FREE_SPACE=$(df -k / | tail -n 1 | awk '{printf $4}')
    FREE_SPACE_READABLE=$(df -h / | tail -n 1 | awk '{printf $4}' | tr -d i)
    FREE_SPACE_READABLE=$COLOR_YELLOW_BOLD$FREE_SPACE_READABLE$COLOR_NONE

    if (($FREE_SPACE <= 5000000)); then
        FREE_SPACE_READABLE=$FREE_SPACE_READABLE' '$COLOR_RED_BOLD'WARNING: Low free disk space!!!'$COLOR_NONE
    fi

    [[ $SH_INTERACTIVE ]] && echo
    [[ $SH_INTERACTIVE ]] && echo -e 'Free space: '$FREE_SPACE_READABLE

    [[ $SH_INTERACTIVE ]] && echo
}

__bashrc_main "$@"
unset -f __bashrc_main
