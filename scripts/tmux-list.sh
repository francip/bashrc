#!/usr/bin/env bash
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)/tmux-sessions.sh"
__tmux_sessions_main list "$@"
tmux_list_result=$?
unset -f __tmux_sessions_main
exit "$tmux_list_result"
