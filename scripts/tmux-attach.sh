#!/usr/bin/env bash
. "$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd -P)/tmux-sessions.sh"
__tmux_sessions_main attach "$@"
tmux_attach_result=$?
unset -f __tmux_sessions_main
exit "$tmux_attach_result"
