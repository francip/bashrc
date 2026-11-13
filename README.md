bashrc
======

The one bashrc to rule them all

To clone:

```
GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa_personal' git clone ...
```

Mac OS X:

Install Homebrew or MacPorts

```
brew install bash-completion
brew install zsh-completions
sudo port install bash-completion
sudo port install zsh-completions
```

Windows:

```
pacman -S git
```

Set MSYS=winsymlinks:nativestrict or CYGWIN=winsymlinks:nativestrict. This will change the behavior of
ln to use mklink and create native Windows symlinks.

WARNING: You need to run install.sh as administrator, as users don't have the permission to create symlinks.
(http://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user)

If the Windows user you are running msys under is not an administrator, run cmd.exe as administrator,
then run msys2 shell and then do 'export $HOME=/home/<username>' befor running the install.sh script

Also, the msys2 vim package comes without 'vi' alias, run cmd.ex as administrator and do in
/usr/bin 'ln -s vi vim.exe'

To share Windows and MSys2 home directories, add the following line to /etc/fstab and relogin to Windows

```
C:/Users /home ntfs binary,noacl,auto 1 1
```

CentOS

```
yum install bash-completion -y
```

## Automatic macOS keychain unlock over SSH

The SSH client sends `SNAPPY_KEYCHAIN_PASSWORD` only when connecting to `snappy`
or `snappy.ts`. On a trusted Linux client, save the password in the local
mode-600 file `~/.ssh/snappy-keychain-password`:

```bash
~/src/bashrc/scripts/set-snappy-keychain-password
```

On the macOS SSH server, install the tracked `sshd` configuration once:

```zsh
sudo install -m 644 ~/src/bashrc/sshd-keychain.conf /etc/ssh/sshd_config.d/100-bashrc-keychain.conf
sudo launchctl kickstart -k system/com.openssh.sshd
```

Interactive SSH clients without the saved password still get the normal
keychain password prompt. Command-only SSH sessions unlock the keychain from
the received password before running their command.

## tmux session listing

`tl` uses the shell helper in `scripts/tmux-list.sh`. It requires Bash, tmux
and standard OS tools; no Node, Python or terminal repository checkout is needed.
Each session gets one line with its name, server name and attachment status:

```text
main  [default]  attached (1 client)
work  [kortexa-terminal]  detached
```

The helper checks the current socket and standard named sockets under `/tmp`,
`TMUX_TMPDIR` and `TMPDIR`. Linux and WSL also inspect owned tmux process
descriptors and `/proc/net/unix` for custom sockets. macOS uses its built-in
`lsof` for custom discovery. Without either metadata source, standard/current
servers still work and the helper reports incomplete discovery. Custom server
paths stay explicit so duplicate names remain distinguishable.

It tries available system/Homebrew clients for version compatibility. Probes
use tmux's no-start flag, have a two-second deadline, and never remove stale
sockets or change sessions. Discovery stops at 64 socket candidates or a
five-second scan budget. `tl --help` describes the command; other arguments
return status 2. Missing tmux returns 127; incomplete discovery returns 1.

Run `bash ./tmux-list-test.sh` and `zsh ./tmux-list-test.sh` (where installed).
They test wrapper routing and create isolated test-owned tmux servers for
named/custom sockets, duplicate and unusual names, and multiple attachments.

## Known hacks

### Windows `shrc.cmd` doesn't load the `aliases` file

- **Symptom:** Aliases added to the Unix-side `aliases` file don't automatically show up in `cmd` on Windows.
- **Cause:** `shrc.cmd` doesn't source `aliases`. It hardcodes a minimal set of `doskey` definitions inline (`ls`, `cat`, `e`, `cld`, `cdx`, `cpl`) and that's the whole list.
- **Workaround:** If you need an alias in `cmd`, duplicate it as a `doskey` line inside `shrc.cmd`.
- **When it breaks again:** Every time a new alias gets added to `aliases` and someone expects it to Just Work in `cmd`. It won't. Edit `shrc.cmd` manually, or finally bite the bullet and teach `shrc.cmd` to parse `aliases` (lol, no — screw that guy).
