#!/usr/bin/env bash
# Run with both bash and zsh. NVM calls use local fixtures only.
set -e

__node_update_test_main() (
    set -e
    local repo_dir shell_name calls fixture_nodes fixture_lts fixture_status
    repo_dir=$(CDPATH='' cd -- "$1" && pwd -P)
    shell_name=${ZSH_VERSION:+zsh}
    shell_name=${shell_name:-bash}

    __sh_color_definitions() { :; }
    __sh_os_definitions() { :; }
    SH_OS_TYPE=OSX
    . "$repo_dir/aliases"

    calls=
    fixture_status=0
    nvm() {
        case "$1" in
            current) echo v24.22.1 ;;
            ls-remote)
                [[ $2 == --no-colors ]]
                [[ $fixture_status == 0 ]] || return "$fixture_status"
                if [[ $3 == --lts ]]; then
                    printf '%s\n' "$fixture_lts"
                else
                    printf '%s\n' "$fixture_nodes"
                fi
                ;;
            alias|use) calls="${calls}$*"$'\n' ;;
            *) echo "Unexpected NVM call: $*" >&2; return 99 ;;
        esac
    }
    __latest_nvm_update() { :; }
    __latest_nvm_install() { calls="${calls}install $*"$'\n'; }
    __latest_nvm_uninstall_old_versions() { calls="${calls}prune $*"$'\n'; }

    fixture_lts='    v24.22.1 (LTS: Krypton)
    v26.12.0 (LTS: Lithium)
->  v26.13.0 (Latest LTS: Lithium)'
    fixture_nodes="$fixture_lts"'
    v27.0.0-alpha.0.0.0
    v27.0.0-beta.1
    v27.0.0-rc.1
    v27.0.0-nightly20261103
    v27.0.0+build.1
    v27.0
    v27.0.0garbage'

    # Prereleases must never be installed or become the default.
    __latest_nvm
    [[ $calls == $'install v26.13.0 v24.22.1\nalias default v26.13.0\nuse v26.13.0\nprune v26.13.0\n' ]]

    # Stable non-LTS releases remain eligible; keep the LTS install too.
    fixture_nodes="$fixture_lts"'
->  v27.0.0
    v28.0.0-alpha.1'
    calls=
    __latest_nvm
    [[ $calls == $'install v26.13.0 v24.22.1\ninstall v27.0.0 v24.22.1\nalias default v27.0.0\nuse v27.0.0\nprune v26.13.0\nprune v27.0.0\n' ]]

    # Apply the same strict filter to the LTS listing.
    fixture_lts="$fixture_lts"'
    v28.0.0-rc.1 (Latest LTS: Future)'
    [[ $(__latest_nvm_stable_version --lts) == v26.13.0 ]]

    # Empty, unavailable, or prerelease-only results fail before any changes.
    local invalid
    for invalid in '' 'N/A' '    v27.0.0-alpha.1' '->  v27.0.0-alpha.1'; do
        fixture_nodes=$invalid
        calls=
        if __latest_nvm; then
            echo "Node update accepted an invalid release listing: $invalid" >&2
            exit 1
        fi
        [[ -z $calls ]]
    done
    fixture_lts='    v28.0.0-rc.1 (Latest LTS: Future)'
    calls=
    if __latest_nvm; then
        echo 'Node update accepted a prerelease-only LTS listing' >&2
        exit 1
    fi
    [[ -z $calls ]]

    fixture_status=17
    if __latest_nvm; then
        echo 'Node update ignored a failed release lookup' >&2
        exit 1
    else
        [[ $? == 17 ]]
    fi
    [[ -z $calls ]]

    echo "$shell_name: Node update tests passed"
)

__node_update_test_main "$(dirname -- "$0")/.." "$@"
unset -f __node_update_test_main
