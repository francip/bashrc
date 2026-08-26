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

## Known hacks

### Windows `shrc.cmd` doesn't load the `aliases` file

- **Symptom:** Aliases added to the Unix-side `aliases` file don't automatically show up in `cmd` on Windows.
- **Cause:** `shrc.cmd` doesn't source `aliases`. It hardcodes a minimal set of `doskey` definitions inline (`ls`, `cat`, `e`, `cld`, `cdx`, `cpl`) and that's the whole list.
- **Workaround:** If you need an alias in `cmd`, duplicate it as a `doskey` line inside `shrc.cmd`.
- **When it breaks again:** Every time a new alias gets added to `aliases` and someone expects it to Just Work in `cmd`. It won't. Edit `shrc.cmd` manually, or finally bite the bullet and teach `shrc.cmd` to parse `aliases` (lol, no — screw that guy).
