# Avoid nested tmux over SSH

Owning issue: <https://github.com/francip/bashrc/issues/5>.

SSH carries the source terminal type when it requests a pseudo-terminal. Both
Bash and Zsh skip SSH tmux auto-attach for `screen*` and `tmux*` terminal types,
including tmux-backed web terminals. Keep normal-terminal auto-attach, existing
opt-outs, and the explicit `ssht` helper. Do not forward a source tmux socket
to another machine. Custom terminal types outside those families are not detected.

Validate the actual startup blocks in isolated shells with a fixture tmux client:
normal and multiplexed terminals, local shells, shells already in tmux,
non-interactive SSH commands, and `TMUX_AUTO_ATTACH=0`. Run under Linux Bash and
macOS Bash/Zsh to cover the shell and OS combinations used across the machines.
