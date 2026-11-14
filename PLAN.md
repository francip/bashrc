# Attach across tmux servers

Issue: https://github.com/francip/bashrc/issues/4

Share the existing bounded, shell-only server discovery between `tl` and `t`.
Resolve exact session names and use the matching client and socket to attach;
switch directly when the session is on the current server. Allow a server
label or socket path to distinguish duplicate names. Preserve creation on the
current/default server only after a complete search finds no matching session.

Validate with isolated tmux servers, covering named and custom sockets,
duplicate names, literal names, same-server switching, cross-server attachment,
missing sessions, incomplete discovery, and the existing listing regression suite.
