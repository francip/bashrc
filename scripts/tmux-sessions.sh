#!/usr/bin/env bash
# Local CLI discovery is separate from the web broker's stricter admission checks.
__tmux_sessions_main() (
    local mode=$1
    shift
    local uid directory socket process name executable link inode label format seen_socket
    local temporary_root command_pid timer_pid result complete=1 found=0 seen=$'\n'
    local processed=0 descriptors=0 inodes=' ' started=$SECONDS queried
    local session_name server current_socket current_executable default_executable record session_id
    local matches=0 match_socket match_executable match_id escaped_name
    local binaries=() sockets=() directories=() live_sockets=() unique_binaries=() unique_sockets=()
    if [ -n "${ZSH_VERSION:-}" ]; then setopt nonomatch; fi

    if [ "$mode" = attach ]; then
        if [ "$#" -gt 2 ] || { [ "$#" -eq 1 ] && [ "$1" = --help ]; }; then
            echo 'Usage: t [session [server]]'
            echo 'Attach across owned tmux servers; default session: main. Create if missing.'
            echo 'For duplicate names, pass the server label or full socket path shown by tl.'
            [ "$#" -eq 1 ] && [ "$1" = --help ]
            return $(( $? == 0 ? 0 : 2 ))
        fi
        session_name=${1:-main}
        server=${2:-}
    elif [ "$#" -gt 0 ]; then
        echo 'Usage: tl [--help]'
        echo 'List session name, server name, and attached/detached status across owned tmux servers.'
        [ "$#" -eq 1 ] && [ "$1" = --help ]
        return $(( $? == 0 ? 0 : 2 ))
    fi
    uid=$(id -u) || return 1
    executable=$(command -v tmux) || { echo 'tmux is not installed.' >&2; return 127; }
    default_executable=$executable
    binaries=("$executable" /usr/bin/tmux /usr/local/bin/tmux /opt/homebrew/bin/tmux /home/linuxbrew/.linuxbrew/bin/tmux)
    directories=("/tmp/tmux-$uid" "${TMUX_TMPDIR:-/tmp}/tmux-$uid" "${TMPDIR:-/tmp}/tmux-$uid")
    if [ -n "${TMUX:-}" ]; then
        # Socket paths can contain commas; remove the two trailing numeric fields only.
        socket=${TMUX%,*}; sockets+=("${socket%,*}")
        current_socket=${socket%,*}
    fi
    for directory in "${directories[@]}"; do
        [ -d "$directory" ] && [ -O "$directory" ] && [ ! -L "$directory" ] || continue
        for socket in "$directory"/*; do sockets+=("$socket"); done
    done

    temporary_root=$(mktemp -d "${TMPDIR:-/tmp}/bashrc-tl.XXXXXX") || return 1
    trap 'rm -rf "${temporary_root:?}"' EXIT

    # Portable deadline: macOS does not ship the GNU timeout command. Only the
    # exact child started here can be signalled; listing never kills a server.
    __tmux_list_run() {
        rm -f "${temporary_root:?}/deadline"
        "$@" > "$temporary_root/output" 2> "$temporary_root/error" &
        command_pid=$!
        (
            sleep 2 &
            timer_pid=$!
            trap 'kill "$timer_pid" 2>/dev/null; exit' TERM
            wait "$timer_pid"
            : > "$temporary_root/deadline"
            kill "$command_pid" 2>/dev/null
        ) &
        timer_pid=$!
        if wait "$command_pid" 2>/dev/null; then result=0; else result=$?; fi
        kill "$timer_pid" 2>/dev/null
        wait "$timer_pid" 2>/dev/null
        # Some tmux clients exit zero on SIGTERM even without a server reply.
        if [ -e "$temporary_root/deadline" ]; then result=124; fi
        return "$result"
    }

    if [ -r /proc/net/unix ]; then
        # Linux/WSL: intersect listening sockets with descriptors of owned tmux
        # executables. Do not probe unrelated user sockets or read argv/environ.
        for process in /proc/[0-9]*; do
            processed=$((processed + 1))
            if [ "$processed" -gt 8192 ] || [ "$((SECONDS - started))" -ge 5 ]; then complete=0; break; fi
            [ -O "$process" ] || continue
            IFS= read -r name 2>/dev/null < "$process/comm" || continue
            case $name in tmux*) ;; *) continue ;; esac
            executable=$(readlink "$process/exe" 2>/dev/null) || { complete=0; continue; }
            [ "${executable##*/}" = tmux ] || continue
            [ -r "$process/fd" ] || { complete=0; continue; }
            binaries+=("$executable")
            descriptors=0
            while IFS= read -r link; do
                descriptors=$((descriptors + 1))
                if [ "$descriptors" -gt 4096 ]; then complete=0; break; fi
                case $link in
                    'socket:['*']') inode=${link#*\[}; inode=${inode%\]}; inodes="$inodes$inode " ;;
                esac
            done < <(readlink "$process"/fd/* 2>/dev/null)
        done
        while IFS= read -r socket; do sockets+=("$socket"); live_sockets+=("$socket"); done < <(
            awk -v inodes="$inodes" '$4 == "00010000" && $5 == "0001" && index(inodes, " " $7 " ") {
                for (i = 0; i < 7; i++) sub(/^[^[:space:]]+[[:space:]]+/, "")
                if (substr($0, 1, 1) == "/") print
            }' /proc/net/unix
        )
    elif command -v lsof >/dev/null 2>&1; then
        # macOS: lsof is an OS tool. Limit it to this account's tmux processes.
        if __tmux_list_run lsof -n -P -b -U -a -u "$uid" -c tmux -F n; then
            while IFS= read -r link; do
                case $link in n/*) socket=${link#n}; socket=${socket% type=*}; sockets+=("$socket"); live_sockets+=("$socket") ;; esac
            done < "$temporary_root/output"
        elif [ "$result" -ne 1 ]; then complete=0; fi
    else
        complete=0
    fi

    for executable in "${binaries[@]}"; do
        [ -x "$executable" ] || continue
        queried=0
        for name in "${unique_binaries[@]}"; do
            if [ "$executable" -ef "$name" ]; then queried=1; break; fi
        done
        if [ "$queried" -eq 0 ]; then unique_binaries+=("$executable"); fi
    done
    processed=0
    for socket in "${sockets[@]}"; do
        [ -S "$socket" ] && [ -O "$socket" ] && [ ! -L "$socket" ] || continue
        # Newlines and other controls cannot safely enter a line-oriented inventory.
        case $socket in *[[:cntrl:]]*) complete=0; continue ;; esac
        directory=$(CDPATH='' cd -P -- "${socket%/*}" 2>/dev/null && pwd -P) || continue
        socket="$directory/${socket##*/}"
        case $seen in *$'\n'"$socket"$'\n'*) continue ;; esac
        seen="$seen$socket"$'\n'
        # Published aliases can be hard links to an already discovered socket.
        for seen_socket in "${unique_sockets[@]}"; do
            if [ "$socket" -ef "$seen_socket" ]; then continue 2; fi
        done
        unique_sockets+=("$socket")
        processed=$((processed + 1))
        if [ "$processed" -gt 64 ] || [ "$((SECONDS - started))" -ge 5 ]; then complete=0; break; fi
        label=$socket
        for name in "${directories[@]}"; do
            name=$(CDPATH='' cd -P -- "$name" 2>/dev/null && pwd -P) || continue
            if [ "$directory" = "$name" ]; then label=${socket##*/}; break; fi
        done
        if [ "$mode" = attach ]; then
            if [ -n "$server" ] && [ "$server" != "$label" ] && [ "$server" != "$socket" ]; then continue; fi
            format='#{session_id} #{session_name}'
        else
            # Escape format markers in socket names, including #(shell-command).
            label=${label//"#"/"##"}
            format='#{session_name}  ['"$label"']  #{?session_attached,attached (#{session_attached} #{?#{==:#{session_attached},1},client,clients}),detached}'
        fi
        queried=0
        for executable in "${unique_binaries[@]}"; do
            [ -x "$executable" ] || continue
            if [ "$((SECONDS - started))" -ge 5 ]; then complete=0; break; fi
            if __tmux_list_run "$executable" -N -S "$socket" list-sessions -F "$format"; then
                queried=1
                if [ -n "$current_socket" ] && [ "$socket" -ef "$current_socket" ]; then current_executable=$executable; fi
                if [ -s "$temporary_root/output" ]; then
                    if [ "$mode" = attach ]; then
                        while IFS= read -r record; do
                            session_id=${record%% *}
                            name=${record#* }
                            [ "$name" = "$session_name" ] || continue
                            matches=$((matches + 1))
                            match_socket=$socket
                            match_executable=$executable
                            match_id=$session_id
                            printf '%s  [%s]\n' "$name" "$label" >> "$temporary_root/matches"
                        done < "$temporary_root/output"
                    else
                        # tmux escapes control bytes in session names. Also suppress any
                        # remaining terminal controls without interpreting name contents.
                        LC_ALL=C sed 's/[[:cntrl:]]/?/g' "$temporary_root/output"
                    fi
                    found=1
                fi
                break
            fi
        done
        # Failed probes include normal stale sockets. Never unlink or recover them.
        if [ "$queried" -eq 0 ]; then
            for name in "${live_sockets[@]}"; do
                directory=$(CDPATH='' cd -P -- "${name%/*}" 2>/dev/null && pwd -P) || continue
                if [ "$socket" = "$directory/${name##*/}" ]; then complete=0; break; fi
            done
        fi
    done
    if [ "$mode" = list ] && [ "$found" -eq 0 ]; then echo 'No sessions found.'; fi
    if [ "$complete" -eq 0 ]; then
        echo 'Discovery is incomplete; custom servers may be missing.' >&2
        return 1
    fi
    [ "$mode" = attach ] || return 0

    if [ "$matches" -gt 1 ]; then
        echo 'Session name is ambiguous; use t SESSION SERVER with a server shown below:' >&2
        LC_ALL=C sed 's/[[:cntrl:]]/?/g' "$temporary_root/matches" >&2
        return 2
    elif [ "$matches" -eq 1 ]; then
        if [ -n "$current_socket" ] && [ "$match_socket" -ef "$current_socket" ]; then
            "$match_executable" -N -S "$match_socket" switch-client -t "$match_id"
        else
            # A client cannot switch servers. Clear TMUX for a cross-server
            # attachment; detaching returns to the original shell/session.
            TMUX= "$match_executable" -N -S "$match_socket" attach-session -t "$match_id"
        fi
    elif [ -n "$server" ]; then
        echo 'No matching session on that server; use tl to list sessions.' >&2
        return 1
    else
        # new-session expands formats in names; preserve literal # characters.
        escaped_name=${session_name//"#"/"##"}
        if [ -n "$current_socket" ]; then
            executable=${current_executable:-$default_executable}
            session_id=$("$executable" -N -S "$current_socket" new-session -d -P -F '#{session_id}' -s "$escaped_name") || return $?
            "$executable" -N -S "$current_socket" switch-client -t "$session_id"
        else
            "$default_executable" new-session -As "$escaped_name"
        fi
    fi
)
