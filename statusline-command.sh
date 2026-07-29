#!/bin/sh
# Claude Code status line. Mirrors the zsh PROMPT (user, host, cwd, git branch)
# and appends model, context-window use, and session token totals.
#
# Not installed by bash_install.sh / zsh_install.sh: copy to
# ~/.claude/statusline-command.sh and point "statusLine" in ~/.claude/settings.json
# at it. The Windows variant lives in windows/.
#
# Requires jq. Every added segment degrades to silence if jq, the transcript
# path, or the file itself is missing -- the prompt must never break.
input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // .workspace.current_dir // empty')
model=$(echo "$input" | jq -r '.model.display_name // empty')
ctx=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
transcript=$(echo "$input" | jq -r '.transcript_path // empty')

# Git branch (skip optional locks, silent on error)
branch=""
if [ -n "$cwd" ]; then
    branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
fi

# ANSI color codes
BOLD='\033[1m'
GREEN_BG='\033[42m'
YELLOW_BG='\033[43m'
CYAN_BOLD='\033[1;36m'
MAGENTA_BOLD='\033[1;35m'
RESET='\033[0m'

user=$(whoami)
host=$(hostname -s)
dir=${cwd:-$(pwd)}
dir=${dir/#$HOME/\~}

line=""
line="${line}$(printf "${BOLD}${GREEN_BG}%s${RESET}" "$user")"
line="${line} $(printf "${BOLD}${YELLOW_BG}%s${RESET}" "$host")"
line="${line} $(printf "${CYAN_BOLD}%s${RESET}" "$dir")"

if [ -n "$branch" ]; then
    line="${line} $(printf "${MAGENTA_BOLD}[git %s]${RESET}" "$branch")"
fi

if [ -n "$model" ]; then
    line="${line} $(printf "${MAGENTA_BOLD}%s${RESET}" "$model")"
fi

if [ -n "$ctx" ]; then
    line="${line} $(printf "${CYAN_BOLD}ctx:%.0f%%${RESET}" "$ctx")"
fi

# Cumulative session output/cache-creation tokens, computed from the
# transcript JSONL (the stdin payload only has last-call/context-window
# snapshots, never a running session total). cache_read_input_tokens is
# deliberately excluded: it re-reads the same resident context on every
# call, so it swamps everything and measures turn count, not work.
# input_tokens is excluded too: negligible once caching is active.
# Dedup by message.id is NOT optional, for both numbers: each usage object
# appears twice per line, and streaming re-emits the same message id
# repeatedly, so a naive grep/sum over either field double/n-counts and
# inflates the total by ~5x. Keying by id in the awk arrays (last write
# wins) collapses repeats to one value per message before summing. Single
# jq/awk pass emits both fields per id so the transcript is scanned once.
if command -v jq >/dev/null 2>&1 && [ -n "$transcript" ] && [ -f "$transcript" ]; then
    sess_totals=$(jq -r 'select(.message.id and .message.usage) | [.message.id, (.message.usage.output_tokens//0), (.message.usage.cache_creation_input_tokens//0)] | @tsv' "$transcript" 2>/dev/null \
        | awk -F'\t' '{o[$1]=$2; c[$1]=$3} END {to=0; tc=0; for (k in o) {to+=o[k]; tc+=c[k]} print to"\t"tc}')
    if [ -n "$sess_totals" ]; then
        out_total=$(printf '%s' "$sess_totals" | cut -f1)
        cache_total=$(printf '%s' "$sess_totals" | cut -f2)
        fmt_tok() { awk -v n="$1" 'BEGIN{ if (n>=1000000) printf "%.1fM", n/1000000; else if (n>=1000) printf "%.0fk", n/1000; else printf "%d", n }'; }
        if [ -n "$out_total" ] && [ "$out_total" != "0" ]; then
            line="${line} $(printf "${CYAN_BOLD}out:%s${RESET}" "$(fmt_tok "$out_total")")"
        fi
        if [ -n "$cache_total" ] && [ "$cache_total" != "0" ]; then
            line="${line} $(printf "${CYAN_BOLD}cache:%s${RESET}" "$(fmt_tok "$cache_total")")"
        fi
    fi
fi

printf "%b\n" "$line"
