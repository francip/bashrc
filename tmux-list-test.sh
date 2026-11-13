#!/usr/bin/env bash
# Run with Bash or Zsh. Native operations target only sockets created by this test.
__tmux_list_test_main() (
    set -e
    local repo_dir test_root shell_name shell_bin tmux_bin call_result default_socket named_socket custom_socket empty_socket
    local default_id named_id custom_id empty_id client_one='' client_two='' stopped_server='' value actual expected socket
    local owned_sockets=()
    repo_dir=$(CDPATH='' cd -- "$1" && pwd -P)
    # Keep Unix socket paths below macOS's 104-byte limit, even with a long TMPDIR.
    test_root=$(mktemp -d /tmp/bashrc-tl-test.XXXXXX)
    shell_name=${ZSH_VERSION:+zsh}; shell_name=${shell_name:-bash}
    shell_bin=$(command -v "$shell_name")
    tmux_bin=$(command -v tmux)
    __tmux_list_test_cleanup() {
        if [ -n "$stopped_server" ]; then kill -CONT "$stopped_server" 2>/dev/null || :; fi
        for socket in "${owned_sockets[@]}"; do
            "$tmux_bin" -N -S "$socket" kill-server >/dev/null 2>&1 || :
        done
        if [ -n "$client_one" ]; then wait "$client_one" 2>/dev/null || :; fi
        if [ -n "$client_two" ]; then wait "$client_two" 2>/dev/null || :; fi
        rm -rf "${test_root:?}"
    }
    trap __tmux_list_test_cleanup EXIT
    cd "$test_root"

    __sh_color_definitions() { :; }
    __sh_os_definitions() { :; }
    SH_OS_TYPE=OSX
    . "$repo_dir/aliases"

    # Verify the actual wrapper's path/argument quoting and failure propagation.
    mkdir -p "$test_root/helper directory/scripts"
    export TL_TEST_LOG="$test_root/calls"
    cat > "$test_root/helper directory/scripts/tmux-list.sh" <<'EOF'
printf '%s\000' "$@" > "$TL_TEST_LOG"
exit 23
EOF
    __get_aliases_dir() { printf '%s\n' "$test_root/helper directory"; }
    if tl 'session name' '' 'literal * [x] $value'; then exit 1; else call_result=$?; fi
    [ "$call_result" -eq 23 ]
    printf '%s\000' 'session name' '' 'literal * [x] $value' > "$test_root/expected"
    cmp "$test_root/expected" "$TL_TEST_LOG"
    __get_aliases_dir() { printf '%s\n' "$repo_dir"; }

    # Any accidental Node/Python dependency fails even if installed on the host.
    mkdir "$test_root/bin"
    for value in node nodejs python python3; do
        printf '#!/bin/sh\necho "Unexpected runtime dependency" >&2\nexit 99\n' > "$test_root/bin/$value"
        chmod +x "$test_root/bin/$value"
    done
    export PATH="$test_root/bin:$PATH"
    export TMUX_TMPDIR="$test_root"
    mkdir -m 700 "$test_root/tmux-$(id -u)" "$test_root/custom #'s, directory"
    default_socket="$test_root/tmux-$(id -u)/default"
    named_socket="$test_root/tmux-$(id -u)/named"
    custom_socket="$test_root/custom #'s, directory/socket#(touch injected)"
    empty_socket="$test_root/tmux-$(id -u)/empty"
    owned_sockets=("$default_socket" "$named_socket" "$custom_socket" "$empty_socket")
    default_id=$("$tmux_bin" -f /dev/null -S "$default_socket" new-session -d -P -F '#{session_id}' -s 'duplicate name' '/bin/sleep 120')
    named_id=$("$tmux_bin" -f /dev/null -S "$named_socket" new-session -d -P -F '#{session_id}' -s 'duplicate name' '/bin/sleep 120')
    # new-session expands its name format; double # stores a literal format marker.
    custom_id=$("$tmux_bin" -f /dev/null -S "$custom_socket" new-session -d -P -F '#{session_id}' -s 'literal [] $value ##(touch injected)' '/bin/sleep 120')
    empty_id=$("$tmux_bin" -f /dev/null -S "$empty_socket" new-session -d -P -F '#{session_id}' -s temporary '/bin/sleep 120')
    "$tmux_bin" -N -S "$empty_socket" set-option -s exit-empty off
    "$tmux_bin" -N -S "$empty_socket" kill-session -t "$empty_id"
    export TMUX="$custom_socket,123,0"
    ln -s "$custom_socket" "$test_root/tmux-$(id -u)/symlink"

    actual=$("$shell_bin" "$repo_dir/scripts/tmux-list.sh")
    printf '%s\n' "$actual" | grep -F -x 'duplicate name  [default]  detached'
    printf '%s\n' "$actual" | grep -F -x 'duplicate name  [named]  detached'
    expected='literal [] $value #(touch injected)  ['"$custom_socket"']  detached'
    # macOS resolves /tmp to /private/tmp in socket paths.
    expected=${expected/\[\/tmp\//\["$(CDPATH='' cd /tmp && pwd -P)"/}
    printf '%s\n' "$actual" | grep -F -x "$expected"
    # Also prove platform discovery finds a custom server outside the current socket.
    actual=$(TMUX= "$shell_bin" "$repo_dir/scripts/tmux-list.sh")
    printf '%s\n' "$actual" | grep -F -x "$expected"
    [ "$(printf '%s\n' "$actual" | grep -F -c 'socket#(touch injected)]')" -eq 1 ]
    [ ! -e injected ]
    if "$shell_bin" "$repo_dir/scripts/tmux-list.sh" --bad-option >/dev/null; then exit 1; else [ "$?" -eq 2 ]; fi
    "$shell_bin" "$repo_dir/scripts/tmux-list.sh" --help >/dev/null

    # Control-mode clients need no interactive TTY and give exact one/two-client cases.
    mkfifo "$test_root/one" "$test_root/two"
    "$tmux_bin" -N -S "$default_socket" -C attach-session -t "$default_id" < "$test_root/one" >/dev/null 2>&1 &
    client_one=$!
    exec 7> "$test_root/one"
    __tmux_list_test_clients() {
        local attempts=0
        while [ "$attempts" -lt 100 ]; do
            value=$("$tmux_bin" -N -S "$default_socket" display-message -p -t "$default_id" '#{session_attached}')
            if [ "$value" = "$1" ]; then return; fi
            attempts=$((attempts + 1)); sleep 0.02
        done
        echo "$shell_name: attachment count did not settle" >&2
        return 1
    }
    __tmux_list_test_clients 1
    actual=$(tl)
    printf '%s\n' "$actual" | grep -F -x 'duplicate name  [default]  attached (1 client)'
    "$tmux_bin" -N -S "$default_socket" -C attach-session -t "$default_id" < "$test_root/two" >/dev/null 2>&1 &
    client_two=$!
    exec 8> "$test_root/two"
    __tmux_list_test_clients 2
    actual=$("$shell_bin" "$repo_dir/scripts/tmux-list.sh")
    printf '%s\n' "$actual" | grep -F -x 'duplicate name  [default]  attached (2 clients)'

    # Older tmux stores controls as visible escapes; newer versions reject the name.
    if "$tmux_bin" -N -S "$named_socket" rename-session -t "$named_id" $'name\twith\nnewline\033[31m' 2>/dev/null; then
        actual=$("$shell_bin" "$repo_dir/scripts/tmux-list.sh")
        printf '%s\n' "$actual" | grep -F -x 'name\twith\nnewline\033[31m  [named]  detached'
    fi
    [ ! -e injected ]
    # Ending our named fixture leaves a stale socket on tmux versions which retain it.
    "$tmux_bin" -N -S "$named_socket" kill-session -t "$named_id"
    "$shell_bin" "$repo_dir/scripts/tmux-list.sh" >/dev/null

    printf 'detach-client\n' >&7
    printf 'detach-client\n' >&8
    exec 7>&- 8>&-
    wait "$client_one"; client_one=''
    wait "$client_two"; client_two=''
    __tmux_list_test_clients 0

    # An unresponsive test-owned server must time out without being ended or recovered.
    stopped_server=$("$tmux_bin" -N -S "$empty_socket" display-message -p '#{pid}')
    kill -STOP "$stopped_server"
    if "$shell_bin" "$repo_dir/scripts/tmux-list.sh" > "$test_root/stalled-output" 2> "$test_root/stalled-error"; then
        exit 1
    else
        [ "$?" -eq 1 ]
    fi
    kill -CONT "$stopped_server"
    grep -F 'Discovery is incomplete' "$test_root/stalled-error"
    [ "$("$tmux_bin" -N -S "$empty_socket" display-message -p '#{pid}')" = "$stopped_server" ]
    stopped_server=''

    # A tiny PATH fixture covers missing tmux without changing HOME.
    mkdir "$test_root/empty-tools"
    printf '#!/bin/sh\nprintf "424242\\n"\n' > "$test_root/empty-tools/id"
    chmod +x "$test_root/empty-tools/id"
    if PATH="$test_root/empty-tools" "$shell_bin" "$repo_dir/scripts/tmux-list.sh" >/dev/null 2>&1; then
        exit 1
    else
        [ "$?" -eq 127 ]
    fi
    echo "$shell_name: shell-only tmux listing tests passed"
)

__tmux_list_test_main "$(dirname -- "$0")" "$@"
tmux_list_test_result=$?
unset -f __tmux_list_test_main
exit "$tmux_list_test_result"
