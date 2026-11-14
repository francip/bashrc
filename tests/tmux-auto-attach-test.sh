#!/usr/bin/env bash
# Run with both bash and zsh. No SSH connections or tmux servers are started.

__tmux_auto_attach_test_main() (
    set -e
    local repo_dir test_root shell_name shell_bin rc term actual expected
    local -a shell_flags
    repo_dir=$(CDPATH='' cd -- "$1" && pwd -P)
    test_root=$(mktemp -d "${TMPDIR:-/tmp}/bashrc-auto-attach.XXXXXX")
    trap 'rm -rf "${test_root:?}"' EXIT
    shell_name=${ZSH_VERSION:+zsh}
    shell_name=${shell_name:-bash}
    shell_bin=$(command -v "$shell_name")
    if [[ $shell_name == zsh ]]; then
        shell_flags=(-df)
    else
        shell_flags=(--noprofile --norc)
    fi

    mkdir "$test_root/bin"
    cat > "$test_root/bin/tmux" <<'EOF'
#!/bin/sh
printf 'tmux'
printf ' <%s>' "$@"
printf '\n'
EOF
    chmod +x "$test_root/bin/tmux"
    export PATH="$test_root/bin:$PATH"

    __tmux_auto_attach_test_case() {
        local interactive=$1 term=$2 connection=$3 tmux=$4 auto_attach=$5 expected=$6
        local mode=-c
        [[ $interactive == yes ]] && mode=-ic
        actual=$(env TERM="$term" SSH_CONNECTION="$connection" TMUX="$tmux" \
            TMUX_AUTO_ATTACH="$auto_attach" "$shell_bin" "${shell_flags[@]}" "$mode" '
                __tmux_auto_attach_target_session() { echo fixture-session; }
                . "$1"
                echo skipped
            ' auto-attach-test "$test_root/$rc" 2>"$test_root/stderr")
        if [[ $actual != "$expected" ]]; then
            printf '%s %s: unexpected result for TERM=%s interactive=%s SSH_CONNECTION=%s TMUX=%s TMUX_AUTO_ATTACH=%s\n' \
                "$shell_name" "$rc" "$term" "$interactive" "$connection" "$tmux" "$auto_attach" >&2
            printf 'Expected: %s\nActual: %s\n' "$expected" "$actual" >&2
            cat "$test_root/stderr" >&2
            return 1
        fi
    }

    for rc in bashrc zshrc; do
        # Exercise the shipped auto-attach block without unrelated startup side effects.
        awk '/# Auto-attach to tmux on SSH login/ { copying=1 }
             copying && /# Non-interactive shells/ { exit }
             copying { print }' "$repo_dir/$rc" > "$test_root/$rc"
        [[ -s "$test_root/$rc" ]]
        expected='tmux <new-session> <-As> <fixture-session>'
        for term in xterm xterm-256color xterm-ghostty; do
            __tmux_auto_attach_test_case yes "$term" '192.0.2.1 1234 192.0.2.2 22' '' '' "$expected"
        done
        for term in screen screen-256color screen.xterm-256color tmux tmux-256color; do
            __tmux_auto_attach_test_case yes "$term" '192.0.2.1 1234 192.0.2.2 22' '' '' skipped
            __tmux_auto_attach_test_case yes "$term" '192.0.2.1 1234 192.0.2.2 22' '' 1 skipped
        done
        __tmux_auto_attach_test_case yes xterm-256color '' '' '' skipped
        __tmux_auto_attach_test_case yes xterm-256color '192.0.2.1 1234 192.0.2.2 22' '/tmp/tmux-fixture/default,1234,0' '' skipped
        __tmux_auto_attach_test_case yes xterm-256color '192.0.2.1 1234 192.0.2.2 22' '' 0 skipped
        __tmux_auto_attach_test_case no xterm-256color '192.0.2.1 1234 192.0.2.2 22' '' '' skipped
    done

    echo "$shell_name: SSH tmux auto-attach tests passed"
)

__tmux_auto_attach_test_main "$(dirname -- "$0")/.." "$@"
tmux_auto_attach_test_result=$?
unset -f __tmux_auto_attach_test_main
exit "$tmux_auto_attach_test_result"
