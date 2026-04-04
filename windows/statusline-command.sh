#!/bin/sh
# Statusline script for Claude Code
# Mirrors the prompt style: user(green) host(yellow) path(cyan) git(magenta) model context
input=$(cat)

# Parse all JSON fields in one node invocation (node is guaranteed available
# since Claude Code is a Node.js app; python may be a Windows Store stub)
parsed=$(printf '%s' "$input" | node -e "
var d=JSON.parse(require('fs').readFileSync(0,'utf8'));
function g(o,p){for(var k of p.split('.')){if(o&&typeof o==='object')o=o[k];else return'';}return o!=null&&o!==''?String(o):'';}
console.log(g(d,'cwd')||g(d,'workspace.current_dir'));
console.log(g(d,'model.display_name'));
console.log(g(d,'context_window.used_percentage'));
" 2>/dev/null)

cwd=$(printf '%s\n' "$parsed" | sed -n '1p')
model=$(printf '%s\n' "$parsed" | sed -n '2p')
ctx=$(printf '%s\n' "$parsed" | sed -n '3p')

# Git branch
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
host=$(hostname)
# Trim domain from hostname if present
host=${host%%.*}

dir=${cwd:-$(pwd)}

# Platform-aware path display
case "$(uname -s)" in
    MINGW*|MSYS*)
        # Normalize to POSIX for home-dir comparison
        posix_dir=$(cygpath -u "$dir" 2>/dev/null || printf '%s' "$dir")
        case "$posix_dir" in
            "$HOME"/*)
                # Under home: collapse to ~ with backslashes
                suffix="${posix_dir#"$HOME"}"
                dir="~$(printf '%s' "$suffix" | tr '/' '\\')"
                ;;
            "$HOME")
                dir="~"
                ;;
            *)
                # Not under home: show full Windows path
                dir=$(cygpath -w "$posix_dir" 2>/dev/null || printf '%s' "$dir")
                ;;
        esac
        ;;
    *)
        # Linux/Mac/WSL: POSIX paths with ~ collapsing
        case "$dir" in
            "$HOME"/*) dir="~${dir#"$HOME"}" ;;
            "$HOME") dir="~" ;;
        esac
        ;;
esac

# Build output using %b for color codes and %s for data (avoids backslash
# interpretation in Windows paths like C:\Src which would eat \S as an escape)
printf '%b%s%b %b%s%b %b%s%b' \
    "${BOLD}${GREEN_BG}" "$user" "${RESET}" \
    "${BOLD}${YELLOW_BG}" "$host" "${RESET}" \
    "${CYAN_BOLD}" "$dir" "${RESET}"

if [ -n "$branch" ]; then
    printf ' %b%s%b' "${MAGENTA_BOLD}" "[git $branch]" "${RESET}"
fi

if [ -n "$model" ]; then
    printf ' %b%s%b' "${MAGENTA_BOLD}" "$model" "${RESET}"
fi

if [ -n "$ctx" ]; then
    ctx_int=$(printf "%.0f" "$ctx" 2>/dev/null || echo "$ctx")
    printf ' %b%s%b' "${CYAN_BOLD}" "ctx:${ctx_int}%" "${RESET}"
fi

printf '\n'
