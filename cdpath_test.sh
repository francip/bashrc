#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/bashrc-cdpath.XXXXXX")"
TEST_ROOT="$(CDPATH= cd -- "$TEST_ROOT" && pwd -P)"
trap 'rm -rf "${TEST_ROOT:?}"' EXIT

mkdir -p "$TEST_ROOT/search/target" "$TEST_ROOT/extra" "$TEST_ROOT/start"

test_shell() {
    local shell_bin=$1

    "$shell_bin" -c '
        set -e

        repo_dir=$1
        test_root=$2
        shell_bin=$3

        # Reproduce a new shell inheriting the old, exported configuration.
        export CDPATH="$test_root/search"

        __sh_color_definitions() { :; }
        __sh_os_definitions() { :; }
        . "$repo_dir/shrc_helpers"

        __add_to_cd_path "$test_root/search" "$test_root/extra"

        expected="$test_root/search:$test_root/extra"
        if [[ $CDPATH != "$expected" ]]; then
            echo "$shell_bin: unexpected CDPATH: $CDPATH" >&2
            exit 1
        fi

        if env | grep -q "^CDPATH="; then
            echo "$shell_bin: CDPATH leaked into the environment" >&2
            exit 1
        fi

        builtin cd "$test_root/start"
        builtin cd target >/dev/null
        if [[ $PWD != "$test_root/search/target" ]]; then
            echo "$shell_bin: CDPATH lookup failed: $PWD" >&2
            exit 1
        fi

        if ! "$shell_bin" -c '\''[[ -z ${CDPATH:-} ]]'\''; then
            echo "$shell_bin: child shell inherited a CDPATH value" >&2
            exit 1
        fi
    ' cdpath-test "$SCRIPT_DIR" "$TEST_ROOT" "$shell_bin"

    echo "$shell_bin: Success"
}

test_shell bash
test_shell zsh
