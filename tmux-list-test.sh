#!/usr/bin/env bash
# Run with Bash and Zsh. All helper and tmux calls use local fixtures.
set -e

__tmux_list_test_main() (
    set -e
    local repo_dir test_root shell_name tl_definition fixture_helper installed_helper
    local with_node without_node cmp_bin rm_bin
    repo_dir=$(CDPATH='' cd -- "$1" && pwd -P)
    test_root=$(mktemp -d "${TMPDIR:-/tmp}/bashrc-tmux-list.XXXXXX")
    rm_bin=$(command -v rm)
    cmp_bin=$(command -v cmp)
    trap '"$rm_bin" -rf "${test_root:?}"' EXIT
    shell_name=${ZSH_VERSION:+zsh}
    shell_name=${shell_name:-bash}

    __sh_color_definitions() { :; }
    __sh_os_definitions() { :; }
    SH_OS_TYPE=OSX
    . "$repo_dir/aliases"

    # Exercise the real function with only its fixed helper path redirected.
    # HOME remains unchanged, and no user helper or real tmux command can run.
    tl_definition=$(typeset -f tl)
    [[ $tl_definition == *'$HOME/src/terminal/tools/tl.mjs'* ]]
    tl_definition=$(printf '%s\n' "$tl_definition" | sed 's|[$]HOME/src/terminal/tools/tl.mjs|$fixture_helper|g')
    eval "$tl_definition"

    with_node="$test_root/with node"
    without_node="$test_root/without node"
    fixture_helper="$test_root/helper directory/tl fixture.mjs"
    installed_helper=$fixture_helper
    mkdir -p "$with_node" "$without_node" "$(dirname "$fixture_helper")"
    printf '%s\n' '// Test fixture; stub Node never evaluates this file.' > "$fixture_helper"
    chmod 600 "$fixture_helper"
    export TL_TEST_LOG="$test_root/calls"
    export TL_TEST_NODE_STATUS=0 TL_TEST_TMUX_STATUS=0
    cat > "$with_node/node" <<'EOF'
#!/bin/sh
printf '%s\000' node "$@" >> "$TL_TEST_LOG"
exit "$TL_TEST_NODE_STATUS"
EOF
    cat > "$with_node/tmux" <<'EOF'
#!/bin/sh
printf '%s\000' tmux "$@" >> "$TL_TEST_LOG"
exit "$TL_TEST_TMUX_STATUS"
EOF
    cp "$with_node/tmux" "$without_node/tmux"
    chmod +x "$with_node/node" "$with_node/tmux" "$without_node/tmux"

    __tmux_list_test_expect_call() {
        printf '%s\000' "$@" > "$test_root/expected"
        if ! "$cmp_bin" -s "$test_root/expected" "$TL_TEST_LOG"; then
            echo "$shell_name: unexpected tl command or arguments" >&2
            return 1
        fi
    }

    # Isolate command lookup after all fixture preparation is complete.
    export PATH="$with_node"
    : > "$TL_TEST_LOG"
    tl
    __tmux_list_test_expect_call node "$fixture_helper"

    : > "$TL_TEST_LOG"
    tl --help
    __tmux_list_test_expect_call node "$fixture_helper" --help

    # Even unsupported arguments must reach the helper intact for validation.
    : > "$TL_TEST_LOG"
    tl 'session name' '' 'literal * [x] $value'
    __tmux_list_test_expect_call node "$fixture_helper" 'session name' '' 'literal * [x] $value'

    # A failed helper must not hide its error by falling back to another server.
    TL_TEST_NODE_STATUS=23
    : > "$TL_TEST_LOG"
    if tl; then
        echo "$shell_name: tl ignored a helper failure" >&2
        exit 1
    else
        [[ $? == 23 ]]
    fi
    __tmux_list_test_expect_call node "$fixture_helper"
    TL_TEST_NODE_STATUS=0

    # A missing helper and a directory at the helper path both use tmux ls.
    fixture_helper="$test_root/missing helper.mjs"
    : > "$TL_TEST_LOG"
    tl
    __tmux_list_test_expect_call tmux ls

    fixture_helper="$test_root/helper directory"
    : > "$TL_TEST_LOG"
    tl 'session name' '' 'literal * [x] $value'
    __tmux_list_test_expect_call tmux ls 'session name' '' 'literal * [x] $value'

    # An installed helper without Node must still retain the original listing.
    fixture_helper=$installed_helper
    export PATH="$without_node"
    : > "$TL_TEST_LOG"
    tl
    __tmux_list_test_expect_call tmux ls

    TL_TEST_TMUX_STATUS=29
    : > "$TL_TEST_LOG"
    if tl; then
        echo "$shell_name: tl ignored a tmux failure" >&2
        exit 1
    else
        [[ $? == 29 ]]
    fi
    __tmux_list_test_expect_call tmux ls

    echo "$shell_name: tmux listing tests passed"
)

__tmux_list_test_main "$(dirname -- "$0")" "$@"
unset -f __tmux_list_test_main
