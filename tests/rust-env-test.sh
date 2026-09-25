#!/usr/bin/env bash
# Run with both bash and zsh. All installers and updates use local fixtures.
set -e

__rust_env_test_main() (
    set -e
    local repo_dir test_root original_path shell_name
    repo_dir=$(CDPATH= cd -- "$1" && pwd -P)
    test_root=$(mktemp -d "${TMPDIR:-/tmp}/bashrc-rust.XXXXXX")
    trap 'rm -rf "${test_root:?}"' EXIT
    shell_name=${ZSH_VERSION:+zsh}
    shell_name=${shell_name:-bash}

    __sh_color_definitions() { :; }
    __sh_os_definitions() { :; }
    . "$repo_dir/shrc_helpers"

    export PATH=/usr/bin:/bin
    original_path=$PATH
    export CARGO_HOME="$test_root/cargo home"
    BREW_DIR="$test_root/brew"
    __configure_rust_path
    [[ $PATH == "$original_path" ]]

    # Detect a custom Cargo home even without an installer-generated env file.
    mkdir -p "$CARGO_HOME/bin"
    __configure_rust_path
    [[ $PATH == "$CARGO_HOME/bin:$original_path" ]]
    __configure_rust_path
    [[ $PATH == "$CARGO_HOME/bin:$original_path" ]]

    # The default Cargo home remains supported.
    (
        unset CARGO_HOME
        BREW_DIR=
        __add_to_path() { [[ $1 == "$HOME/.cargo/bin" ]]; }
        __configure_rust_path
    )

    # Reproduce obsolete rustup-init links alongside working Homebrew proxies.
    mkdir -p "$BREW_DIR/opt/rustup/bin"
    ln -s "$test_root/removed-rustup-init" "$CARGO_HOME/bin/rustup"
    ln -s rustup "$CARGO_HOME/bin/cargo"
    ln -s rustup "$CARGO_HOME/bin/rustc"
    export RUST_TEST_LOG="$test_root/rust.log"
    cat > "$BREW_DIR/opt/rustup/bin/rustup" <<'EOF'
#!/bin/sh
printf '%s\n' "$*" >> "$RUST_TEST_LOG"
exit "${RUST_TEST_EXIT:-0}"
EOF
    chmod +x "$BREW_DIR/opt/rustup/bin/rustup"
    ln -s rustup "$BREW_DIR/opt/rustup/bin/cargo"
    ln -s rustup "$BREW_DIR/opt/rustup/bin/rustc"
    __configure_rust_path
    local tool configured_path=$PATH
    for tool in rustup cargo rustc; do
        [[ $(command -v "$tool") == "$BREW_DIR/opt/rustup/bin/$tool" ]]
        "$tool" --version
    done
    __configure_rust_path
    [[ $PATH == "$configured_path" ]]

    SH_OS_TYPE=OSX
    . "$repo_dir/aliases"
    # setup must reuse rustup, update stable, then select it as default.
    curl() { echo 'Unexpected download' >&2; return 99; }
    : > "$RUST_TEST_LOG"
    __setup_rust
    [[ $(cat "$RUST_TEST_LOG") == $'update stable\ndefault stable' ]]
    export RUST_TEST_EXIT=17
    : > "$RUST_TEST_LOG"
    if __setup_rust; then
        echo 'setup ignored a failed toolchain update' >&2
        exit 1
    else
        [[ $? == 17 ]]
    fi
    [[ $(cat "$RUST_TEST_LOG") == 'update stable' ]]
    unset RUST_TEST_EXIT

    # Check the public check_env inventory without querying unrelated tools.
    (
        __get_commands_info() { printf '%s\n' "$@" >> "$test_root/check.log"; }
        check_env >/dev/null
        for tool in rustup cargo rustc; do
            command grep -qx "$tool" "$test_root/check.log"
        done
    )

    # Every OS-specific latest must update Rust, honor skipping, and fail honestly.
    export LATEST_SKIP_BREW=1 LATEST_SKIP_NVM=1 LATEST_SKIP_NPM=1
    export LATEST_SKIP_BUN=1 LATEST_SKIP_PIPX=1 LATEST_SKIP_UV=1
    sudo() { :; }
    pacman() { :; }
    local os
    for os in OSX Linux Windows; do
        SH_OS_TYPE=$os
        SH_OS_DISTRO=Debian
        . "$repo_dir/aliases"
        unset LATEST_SKIP_RUSTUP
        : > "$RUST_TEST_LOG"
        latest
        [[ $(cat "$RUST_TEST_LOG") == update ]]
        LATEST_SKIP_RUSTUP=1
        : > "$RUST_TEST_LOG"
        latest
        [[ ! -s "$RUST_TEST_LOG" ]]
        unset LATEST_SKIP_RUSTUP
        export RUST_TEST_EXIT=18
        if latest; then
            echo "$os latest ignored a failed Rust update" >&2
            exit 1
        else
            [[ $? == 18 ]]
        fi
        unset RUST_TEST_EXIT
    done

    # A fresh install becomes usable immediately, even with an existing rustc.
    export PATH=$original_path
    BREW_DIR=
    export CARGO_HOME="$test_root/fresh cargo"
    export RUST_TEST_PROXY="$test_root/brew/opt/rustup/bin/rustup"
    rustc() { :; }
    __latest_rustup  # Missing rustup is harmless during latest.
    curl() {
        cat <<'EOF'
printf 'install %s\n' "$*" >> "$RUST_TEST_LOG"
mkdir -p "$CARGO_HOME/bin"
cp "$RUST_TEST_PROXY" "$CARGO_HOME/bin/rustup"
EOF
    }
    : > "$RUST_TEST_LOG"
    __setup_rust
    [[ $(command -v rustup) == "$CARGO_HOME/bin/rustup" ]]
    [[ $(cat "$RUST_TEST_LOG") == $'install -y --no-modify-path --default-toolchain stable\nupdate stable\ndefault stable' ]]

    # A download failure must not be masked by the shell at the end of the pipe.
    export PATH=$original_path
    export CARGO_HOME="$test_root/failed cargo"
    curl() { return 19; }
    if __setup_rust; then
        echo 'setup ignored a failed installer download' >&2
        exit 1
    else
        [[ $? == 19 ]]
    fi

    echo "$shell_name: Rust environment tests passed"
)

__rust_env_test_main "$(dirname -- "$0")/.." "$@"
unset -f __rust_env_test_main
