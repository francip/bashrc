# tmux session listing shell integration

Owning issue: <https://github.com/francip/bashrc/issues/1>

Program: <https://github.com/kortexa-ai/terminal/issues/27>

The `tl` shell function invokes the terminal repository's fixed
`$HOME/src/terminal/tools/tl.mjs` helper through Node when both are available.
The helper supplies read-only session discovery across servers owned by the
current user. The shell function passes arguments through unchanged and
preserves the selected command's exit status.

If the helper file or Node is unavailable, `tl` uses `tmux ls` and therefore
lists only the current or default server. Installing this shell repository
does not install the terminal helper or Node. An available helper that fails
returns its error directly.

`tmux-list-test.sh` covers helper routing, fallback, command failures, and
quoted paths and arguments with isolated command fixtures under Bash and
Zsh. It does not change `HOME`, execute the helper, or contact a tmux server.
