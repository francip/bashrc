# Source common definitions

__zshrc_main() {
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

    # Source shared env (idempotent — short-circuits if zshenv already loaded
    # it). Sets SH_OS_*, BREW_DIR exported globally. Defines __add_to_path,
    # __include_files, __sh_color_definitions, ... globally. Configures PATH,
    # nvm, conda, ssh-agent discovery, etc.
    if [[ -f "$SH_SOURCE_DIR/shenv" ]]; then
        . "$SH_SOURCE_DIR/shenv"
    fi

    # Pull COLOR_* into local scope for prompt/banner use (shenv defines the
    # function globally; configure_colors uses 'local' so we re-eval here)
    if (( $+functions[__sh_color_definitions] )); then
        eval "$(__sh_color_definitions)"
    fi

    local SH_INTERACTIVE
    case $- in
    *i*)
        SH_INTERACTIVE=1
        ;;
    esac

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
    [[ $SH_INTERACTIVE ]] && echo -e 'Configuring environment for '$COLOR_GREEN_BOLD'Zsh '$COLOR_YELLOW_BOLD${ZSH_VERSION}$COLOR_NONE' on '$COLOR_GREEN_BOLD$SH_OS_DISTRO$COLOR_NONE' '$COLOR_YELLOW_BOLD$SH_OS_RELEASE$COLOR_NONE' ('$COLOR_GREEN_BOLD$SH_OS_TYPE$COLOR_NONE')'

    if [[ -z "$BREW_DIR" ]]; then
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
        export SSH_AUTH_SOCK=/tmp/.ssh-socket
        ssh-add -l >/dev/null 2>&1
        if [[ $? = 2 ]]; then
            [[ $SH_INTERACTIVE ]] && echo
            [[ $SH_INTERACTIVE ]] && echo -e 'Creating new ssh-agent'
            rm -f /tmp/.ssh-script /tmp/.ssh-agent-pid /tmp/.ssh-socket
            ssh-agent -a $SSH_AUTH_SOCK > /tmp/.ssh-script
            . /tmp/.ssh-script
            [[ $SH_INTERACTIVE ]] && echo $SSH_AGENT_PID > /tmp/.ssh-agent-pid
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

    # Force emacs-style line editing. Without this, zsh auto-picks vi mode
    # because $EDITOR matches *vi* (vim) — coupling shell line editing to
    # file editor preference, which is silly.
    bindkey -e

    # Source additional global, local, and personal definitions
    echo
    __include_files "${HOME}/.zshrc.local" "${HOME}/.zshrc_local" "${SH_SOURCE_DIR}/aliases" "${HOME}/.aliases.local" "${HOME}/.aliases_local"

    # Set up prompt (matching bashrc style: green-bg user, yellow-bg host, cyan path)
    local COLOR_ROOT_INVERT=$COLOR_GREEN_INVERT
    if [[ "$(whoami)" == "root" ]]; then
        COLOR_ROOT_INVERT=$COLOR_RED_INVERT
    fi
    # Git branch for prompt
    __zsh_git_branch() {
        if (( $+functions[__git_ps1] )); then
            __git_ps1 '[git %s] '
        else
            local branch
            branch=$(git symbolic-ref --short HEAD 2>/dev/null)
            [[ -n "$branch" ]] && printf '[git %s] ' "$branch"
        fi
    }

    setopt PROMPT_SUBST
    PROMPT="%{$COLOR_BOLD%}%{$COLOR_ROOT_INVERT%}%n%{$COLOR_NONE%} %{$COLOR_BOLD$COLOR_YELLOW_INVERT%}%m%{$COLOR_NONE%} %{$COLOR_CYAN_BOLD%}%~%{$COLOR_NONE%} %{$COLOR_MAGENTA_BOLD%}\$(__zsh_git_branch)%{$COLOR_NONE%}%# "

    setopt histignorealldups sharehistory auto_cd

    # Keep history within the shell and save it to ~/.zsh_history:
    HISTSIZE=10000
    SAVEHIST=10000
    HISTFILE=~/.zsh_history

    # Color directories
    if [[ $SH_OS_TYPE == OSX ]]; then
        # Mac OS X settings
        export LSCOLORS=GxFxCxDxBxegedabagaced
    fi

    if [[ $SH_OS_TYPE == Linux ]]; then
        # Linux settings
        export LS_COLORS='di=01;36'
    fi

    # Use modern completion system
    # Set ZSH_DISABLE_COMPFIX at global scope to ensure it works in nested zsh sessions
    export ZSH_DISABLE_COMPFIX=true
    autoload -Uz compinit
    compinit -u # Use -u flag to skip the insecure directories check

    zstyle ':completion:*' auto-description 'specify: %d'
    zstyle ':completion:*' completer _expand _complete _correct _approximate
    zstyle ':completion:*' format 'Completing %d'
    zstyle ':completion:*' group-name ''
    zstyle ':completion:*' menu select=2
    # eval "$(dircolors -b)"
    zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
    zstyle ':completion:*' list-colors ''
    zstyle ':completion:*' list-prompt %SAt %p: Hit TAB for more, or the character to insert%s
    zstyle ':completion:*' matcher-list '' 'm:{a-z}={A-Z}' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=* l:|=*'
    zstyle ':completion:*' menu select=long
    zstyle ':completion:*' select-prompt %SScrolling active: current selection at %p%s
    zstyle ':completion:*' use-compctl false
    zstyle ':completion:*' verbose true

    zstyle ':completion:*:(cd|pushd):*' tag-order local-directories path-directories

    zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#)*=0=01;31'
    zstyle ':completion:*:kill:*' command 'ps -u $USER -o pid,%cpu,tty,cputime,cmd'

    # ITerm2 integration
    local ITERM2_INTEGRATION
    if [[ $SH_OS_TYPE == OSX ]]; then
        ITERM2_INTEGRATION=$HOME/.iterm2_shell_integration.zsh
        if [[ -f "$ITERM2_INTEGRATION" ]]; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD$ITERM2_INTEGRATION$COLOR_NONE
            . "$ITERM2_INTEGRATION"
        fi
    fi

    # Zsh completion
    local ZSH_COMPLETION_INSTALLED
    if [[ $SH_OS_TYPE == OSX ]]; then
        if [[ -f ${BREW_DIR}/bin/brew ]]; then
            if [[ -d ${BREW_DIR}/share/zsh-completions ]]; then
                ZSH_COMPLETION_INSTALLED=${BREW_DIR}/share/zsh-completions
                [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD$ZSH_COMPLETION_INSTALLED$COLOR_NONE
                FPATH=$ZSH_COMPLETION_INSTALLED:$FPATH

                # Already called compinit at the top level, just update FPATH
            fi
        fi
    fi

    # NVM completion (env loaded nvm.sh; this is the interactive completion)
    if [[ -d $NVM_DIR && -s "$NVM_DIR/bash_completion" ]]; then
        . "$NVM_DIR/bash_completion"
    fi

    # Bun completion (env added bin to PATH; this is the interactive completion)
    if [[ -d $BUN_INSTALL && -s "$BUN_INSTALL/_bun" ]]; then
        . "$BUN_INSTALL/_bun"
    fi

    # Affects cd behavior - CDPATH needs to always be set for the cd function in aliases to work properly
    __add_to_cd_path "." "${HOME}" "${HOME}/src"

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

    # Git completion and prompt
    if [[ -n $(which git 2>/dev/null) ]]; then
        # Load custom git completions if available
        local GIT_COMPLETION
        GIT_COMPLETION=$HOME/bin/git-completion.zsh

        if [[ -f "$GIT_COMPLETION" ]]; then
            [[ $SH_INTERACTIVE ]] && echo -e 'Loading '$COLOR_YELLOW_BOLD$GIT_COMPLETION$COLOR_NONE
            . "$GIT_COMPLETION"
        fi

        # Load git-prompt.sh for __git_ps1 (used in prompt)
        if (( ! $+functions[__git_ps1] )); then
            if [[ -f /opt/homebrew/etc/bash_completion.d/git-prompt.sh ]]; then
                . /opt/homebrew/etc/bash_completion.d/git-prompt.sh
            fi
        fi
    fi

    # Misc declarations
    if [[ $SH_OS_TYPE == Linux ]]; then
        if [[ $SH_OS_DISTRO == Ubuntu ]]; then
            if [[ -z $SHELL ]]; then
                # Ubuntu does not always define it for some reason
                export SHELL=/usr/bin/env zsh
            fi
        fi
    fi

    # Local declarations
    if [[ -n `whence __zshrc_local_run` ]]; then
        [[ $SH_INTERACTIVE ]] && echo
        [[ $SH_INTERACTIVE ]] && echo -e 'Executing '$COLOR_YELLOW_BOLD$(__zshrc_local)$COLOR_NONE

        __zshrc_local_run "$@"
    fi

    # Convert CDPATH (colon separated string) to cdpath (array) - zsh requires this conversion
    # Unlike bash which just uses CDPATH, zsh needs the cdpath array to be properly set
    cdpath=(${(s.:.)CDPATH})

    # Global aliases deferred load
    if [[ -n `whence __aliases_load` ]]; then
        __aliases_load "$@"
    fi

    # Local aliases deferred load
    if [[ -n `whence __aliases_local_load` ]]; then
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

    if [[ -n $BREW_DIR && -f $BREW_DIR/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]]; then
        if [[ -d $BREW_DIR/share/zsh-syntax-highlighting/highlighters ]]; then
            export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=$BREW_DIR/share/zsh-syntax-highlighting/highlighters
        fi
        source $BREW_DIR/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    fi

    # Free space
    local FREE_SPACE FREE_SPACE_READABLE
    FREE_SPACE=`df -k / | tail -n 1 | awk '{printf $4}'`
    FREE_SPACE_READABLE=`df -h / | tail -n 1 | awk '{printf $4}' | tr -d i`
    FREE_SPACE_READABLE=$COLOR_YELLOW_BOLD$FREE_SPACE_READABLE$COLOR_NONE

    if (( $FREE_SPACE <= 5000000 )); then
        FREE_SPACE_READABLE=$FREE_SPACE_READABLE' '$COLOR_RED_BOLD'WARNING: Low free disk space!!!'$COLOR_NONE
    fi

    [[ $SH_INTERACTIVE ]] && echo
    [[ $SH_INTERACTIVE ]] && echo -e 'Free space: '$FREE_SPACE_READABLE

    [[ $SH_INTERACTIVE ]] && echo
}

__zshrc_main "$@"
unset -f __zshrc_main

# BEGIN Agency MANAGED BLOCK
if [[ ":${PATH}:" != *":/Users/francip/.config/agency/CurrentVersion:"* ]]; then
    export PATH="/Users/francip/.config/agency/CurrentVersion:${PATH}"
fi
# END Agency MANAGED BLOCK
