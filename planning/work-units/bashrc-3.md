# tmux socket alias deduplication

Owning issue: <https://github.com/francip/bashrc/issues/3>.
Related: terminal issue 31 and the standalone shell cutover in bashrc issue 2.

A server's current, standard and process-discovered socket paths can be hard links
to the same socket inode. Compare accepted socket paths with the shell's same-file
test before querying them, while preserving different servers with equal names.
Keep discovery read-only and retain the first encountered server label.

Verify a test-owned hardlinked Unix socket both inside and outside tmux, plus two
distinct servers sharing a session name. Retain the existing Bash/Zsh lifecycle,
quoting, portability and bounded-discovery fixtures. No running user server is a
cleanup target. Deliver through the tested main/HTTPS Sparta shell workflow.
