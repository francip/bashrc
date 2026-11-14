#!/usr/bin/env bash
# Run with Bash or Zsh. Mutations are restricted to this test's sockets.
__tmux_attach_test_main() (
    set -e
    local repo_dir test_root test_suffix shell_name shell_bin tmux_bin socket default_socket named_socket custom_socket
    local session_name duplicate_name literal_name first_id first_pane server_pid client_pid='' stopped_server=''
    local actual call_result attempt value
    repo_dir=$(CDPATH='' cd -- "$1" && pwd -P)
    test_root=$(mktemp -d /tmp/bashrc-t-test.XXXXXX)
    test_root=$(CDPATH='' cd -- "$test_root" && pwd -P)
    test_suffix=${test_root##*/}; test_suffix=${test_suffix//./-}
    shell_name=${ZSH_VERSION:+zsh}; shell_name=${shell_name:-bash}
    shell_bin=$(command -v "$shell_name")
    tmux_bin=$(command -v tmux)
    __tmux_attach_test_cleanup() {
        if [ -n "$stopped_server" ]; then kill -CONT "$stopped_server" 2>/dev/null || :; fi
        for socket in "$default_socket" "$named_socket" "$custom_socket"; do
            [ -n "$socket" ] && "$tmux_bin" -N -S "$socket" kill-server >/dev/null 2>&1 || :
        done
        if [ -n "$client_pid" ]; then wait "$client_pid" 2>/dev/null || :; fi
        rm -rf "${test_root:?}"
    }
    trap __tmux_attach_test_cleanup EXIT
    cd "$test_root"
    __sh_color_definitions() { :; }
    __sh_os_definitions() { :; }
    SH_OS_TYPE=OSX
    . "$repo_dir/aliases"

    # Exercise the actual alias's argument quoting and status propagation.
    mkdir -p "$test_root/helper directory/scripts"
    export T_TEST_LOG="$test_root/calls"
    cat > "$test_root/helper directory/scripts/tmux-attach.sh" <<'EOF'
printf '%s\000' "$@" > "$T_TEST_LOG"
exit 23
EOF
    __get_aliases_dir() { printf '%s\n' "$test_root/helper directory"; }
    if t 'session name' 'literal * [x] $value'; then exit 1; else call_result=$?; fi
    [ "$call_result" -eq 23 ]
    printf '%s\000' 'session name' 'literal * [x] $value' > "$test_root/expected"
    cmp "$test_root/expected" "$T_TEST_LOG"
    __get_aliases_dir() { printf '%s\n' "$repo_dir"; }

    export TMUX_TMPDIR="$test_root" TMUX='' TMUX_PANE='' ZDOTDIR="$test_root"
    export T_TEST_ROOT="$test_root" T_TEST_TMUX="$tmux_bin"
    mkdir -m 700 "$test_root/tmux-$(id -u)" "$test_root/custom #'s, directory" "$test_root/bin"
    default_socket="$test_root/tmux-$(id -u)/default"
    named_socket="$test_root/tmux-$(id -u)/named"
    custom_socket="$test_root/custom #'s, directory/socket#(touch injected)"
    session_name="web-$test_suffix-session"
    duplicate_name="duplicate-$test_suffix"
    literal_name='literal [] #(touch injected) '
    "$tmux_bin" -f /dev/null -S "$default_socket" new-session -ds "$duplicate_name" '/bin/sleep 120'
    "$tmux_bin" -f /dev/null -S "$named_socket" new-session -ds "$session_name" '/bin/sleep 120'
    "$tmux_bin" -N -S "$named_socket" new-session -ds "$duplicate_name" '/bin/sleep 120'
    first_id=$("$tmux_bin" -f /dev/null -S "$custom_socket" new-session -d -P -F '#{session_id}' -s "${literal_name//"#"/"##"}" '/bin/sleep 120')
    first_pane=$("$tmux_bin" -N -S "$custom_socket" display-message -p -t "$first_id" '#{pane_id}')
    server_pid=$("$tmux_bin" -N -S "$custom_socket" display-message -p '#{pid}')

    # Discover with the real client. Turn attachments into short real control-mode
    # clients so tests need no TTY. Guard every mutation against user servers.
    cat > "$test_root/bin/tmux" <<'EOF'
#!/usr/bin/env bash
socket="${TMUX%%,*}"
while [ "$#" -gt 0 ]; do
    case $1 in
        -N) shift ;;
        -S) socket=$2; shift 2 ;;
        *) break ;;
    esac
done
command=$1; shift
case $command in
    list-sessions) exec "$T_TEST_TMUX" -N -S "$socket" "$command" "$@" ;;
    attach-session|switch-client|new-session)
        socket=${socket:-$TMUX_TMPDIR/tmux-$(id -u)/default}
        case $socket in "$T_TEST_ROOT"/*) ;; *) echo 'Refusing mutation of a non-test server' >&2; exit 99 ;; esac
        printf '%s\000' "$command" "$socket" "${TMUX:-}" "$@" > "$T_TEST_LOG"
        ;;
    *) echo "Unexpected test command: $command" >&2; exit 99 ;;
esac
if [ -n "${T_TEST_ATTACH_RESULT:-}" ]; then exit "$T_TEST_ATTACH_RESULT"; fi
case $command in
    attach-session)
        exec "$T_TEST_TMUX" -C -N -S "$socket" "$command" "$@" \; display-message -p 'ATTACHED #{session_name}' \; detach-client ;;
    new-session)
        case $1 in
            -As) exec "$T_TEST_TMUX" -C -S "$socket" "$command" "$@" '/bin/sleep 120' \; display-message -p 'CREATED #{session_name}' \; detach-client ;;
            *) exec "$T_TEST_TMUX" -S "$socket" "$command" "$@" '/bin/sleep 120' ;;
        esac ;;
    *) exec "$T_TEST_TMUX" -N -S "$socket" "$command" "$@" ;;
esac
EOF
    chmod +x "$test_root/bin/tmux"
    export PATH="$test_root/bin:$PATH"
    __tmux_attach_test_call() {
        printf '%s\000' "$@" > "$test_root/expected"
        cmp "$test_root/expected" "$T_TEST_LOG"
    }
    __tmux_attach_test_no_call() { [ ! -s "$T_TEST_LOG" ]; }

    actual=$(t "$session_name")
    printf '%s\n' "$actual" | grep -F -x "ATTACHED $session_name"
    __tmux_attach_test_call attach-session "$named_socket" '' -t '$0'
    # Calling the script directly under either shell must work too.
    actual=$("$shell_bin" "$repo_dir/scripts/tmux-attach.sh" "$literal_name")
    printf '%s\n' "$actual" | grep -F -x "ATTACHED $literal_name"
    __tmux_attach_test_call attach-session "$custom_socket" '' -t '$0'
    [ ! -e injected ]

    : > "$T_TEST_LOG"
    if t "$duplicate_name" > /dev/null 2> "$test_root/error"; then exit 1; else [ "$?" -eq 2 ]; fi
    grep -F 'ambiguous' "$test_root/error"
    grep -F '[default]' "$test_root/error"
    grep -F '[named]' "$test_root/error"
    __tmux_attach_test_no_call
    actual=$(t "$duplicate_name" named)
    printf '%s\n' "$actual" | grep -F -x "ATTACHED $duplicate_name"
    __tmux_attach_test_call attach-session "$named_socket" '' -t '$1'
    actual=$(t "$literal_name" "$custom_socket")
    printf '%s\n' "$actual" | grep -F -x "ATTACHED $literal_name"

    # Exact name lookup must not attach to an existing prefix match.
    actual=$(t "${session_name%-*}")
    printf '%s\n' "$actual" | grep -F -x "CREATED ${session_name%-*}"
    actual=$(t "new-$test_suffix ##(touch injected)")
    printf '%s\n' "$actual" | grep -F -x "CREATED new-$test_suffix ##(touch injected)"
    [ ! -e injected ]
    : > "$T_TEST_LOG"
    if t missing named >/dev/null 2> "$test_root/error"; then exit 1; else [ "$?" -eq 1 ]; fi
    __tmux_attach_test_no_call
    if t a b c >/dev/null; then exit 1; else [ "$?" -eq 2 ]; fi
    t --help >/dev/null

    # One persistent client proves same-server switching with commas in TMUX's
    # socket path. Cross-server attachment leaves that original client in place.
    mkfifo "$test_root/client-input"
    "$tmux_bin" -N -S "$custom_socket" -C attach-session -t "$first_id" < "$test_root/client-input" > "$test_root/client-output" &
    client_pid=$!
    exec 7> "$test_root/client-input"
    for attempt in $(seq 1 100); do
        value=$("$tmux_bin" -N -S "$custom_socket" list-clients -F '#{session_name}')
        [ "$value" = "$literal_name" ] && break
        sleep 0.02
    done
    [ "$value" = "$literal_name" ]
    export TMUX="$custom_socket,$server_pid,0" TMUX_PANE="$first_pane"
    t "switch-$test_suffix"
    [ "$("$tmux_bin" -N -S "$custom_socket" list-clients -F '#{session_name}')" = "switch-$test_suffix" ]
    t "$literal_name"
    __tmux_attach_test_call switch-client "$custom_socket" "$TMUX" -t "$first_id"
    [ "$("$tmux_bin" -N -S "$custom_socket" list-clients -F '#{session_name}')" = "$literal_name" ]
    actual=$(t "$session_name")
    printf '%s\n' "$actual" | grep -F -x "ATTACHED $session_name"
    __tmux_attach_test_call attach-session "$named_socket" '' -t '$0'
    [ "$("$tmux_bin" -N -S "$custom_socket" list-clients -F '#{session_name}')" = "$literal_name" ]
    printf 'detach-client\n' >&7
    exec 7>&-
    wait "$client_pid"; client_pid=''
    export TMUX='' TMUX_PANE=''

    # Propagate attachment failure, and never create after incomplete discovery.
    export T_TEST_ATTACH_RESULT=37
    if t "$session_name" >/dev/null; then exit 1; else [ "$?" -eq 37 ]; fi
    unset T_TEST_ATTACH_RESULT
    stopped_server=$("$tmux_bin" -N -S "$custom_socket" display-message -p '#{pid}')
    kill -STOP "$stopped_server"
    : > "$T_TEST_LOG"
    if t "missing-$test_suffix" > /dev/null 2> "$test_root/error"; then exit 1; else [ "$?" -eq 1 ]; fi
    grep -F 'Discovery is incomplete' "$test_root/error"
    __tmux_attach_test_no_call
    kill -CONT "$stopped_server"; stopped_server=''
    echo "$shell_name: cross-server tmux attachment tests passed"
)

__tmux_attach_test_main "$(dirname -- "$0")/.." "$@"
tmux_attach_test_result=$?
unset -f __tmux_attach_test_main
exit "$tmux_attach_test_result"
