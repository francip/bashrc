# zshenv — sourced for ALL zsh invocations (interactive, non-interactive,
# login, non-login). Keep this file MINIMAL — only env that must be
# available everywhere, including for `ssh host 'cmd'` style remote commands.
#
# Why this exists: ~/.zshrc is NOT sourced for non-interactive zsh, so
# ssh-agent socket discovery there only helps interactive shells. Putting
# the discovery here means scp, remote git, cron-from-ssh, etc. all see it.
#
# Anything more involved (prompt, aliases, completion, MOTD) belongs in
# ~/.zshrc, NOT here.

# ---------------------------------------------------------------------------
# SSH agent socket discovery
# ---------------------------------------------------------------------------
# macOS launchd-managed ssh-agent: socket path changes each boot and after
# sleep/wake, and is NOT exported via launchctl getenv to non-login shells.
# Find it by walking the well-known launchd socket directory.
#
# Linux user ssh-agent: socket lives under /tmp/ssh-* with restrictive perms.

case "$(uname)" in
    Darwin)
        if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
            # macOS 26+ moved sockets from /private/tmp to /var/run
            _sock=$(find /private/tmp /var/run -path "*/com.apple.launchd.*/Listeners" -user "$USER" 2>/dev/null | head -1)
            [[ -S "$_sock" ]] && export SSH_AUTH_SOCK="$_sock"
            unset _sock
        fi
        ;;
    Linux)
        if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
            _sock=$(find /tmp/ssh-* -name 'agent.*' -user "$USER" 2>/dev/null | head -1)
            [[ -S "$_sock" ]] && export SSH_AUTH_SOCK="$_sock"
            unset _sock
        fi
        ;;
esac

# Rust toolchain (Cargo) — needed in non-interactive contexts too
[[ -f "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"
