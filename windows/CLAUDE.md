# Windows OpenSSH -> WSL Setup

## Problem

Windows OpenSSH sshd was refusing all connections on port 22. The sshd service was
running and listening, firewall was open, but every login attempt was rejected at
the pre-auth stage with:

    User franci penov not allowed because shell c:\windows\system32\bash.exe does not exist

The registry key `HKLM\SOFTWARE\OpenSSH\DefaultShell` pointed to
`C:\Windows\System32\bash.exe`, which Microsoft removed from Windows in favor of
`wsl.exe`. sshd validates the shell path before authenticating and rejects the
user entirely if the shell doesn't exist.

## Solution

### 1. wsl-shell.exe (compiled C# wrapper)

`wsl.exe` can't be used directly as the default shell because OpenSSH passes
commands using `-c "command"` and `wsl.exe` doesn't understand `-c`. OpenSSH also
quotes `DefaultShellCommandOption` as a single token, so multi-word options like
`-- bash -c` don't work either. A `.bat` wrapper was tried but cmd.exe fails to
open CONIN$ in sshd's headless context, corrupting exit codes (always returns 1).

The fix is `wsl-shell.exe`, a small C# program that:
- Receives `-c "command"` from OpenSSH
- Translates it to `wsl.exe -- bash -l -c "cd && command"` (login shell, home dir)
- Launches interactive login shell (`bash -li`) when called with no arguments
- Passes `SSH_CONNECTION` into WSL via `WSLENV` so bashrc can detect SSH sessions
  (Windows sshd doesn't propagate this to WSL natively)
- Properly propagates exit codes

Source is `wsl-shell.cs`. Compile with:

    C:\Windows\Microsoft.NET\Framework64\v4.0.30319\csc.exe /nologo /out:C:\ProgramData\ssh\wsl-shell.exe /target:exe wsl-shell.cs

### 2. Registry keys

Exported in `openssh_registry.reg`. The key setting is:

    HKLM\SOFTWARE\OpenSSH
        DefaultShell = C:\ProgramData\ssh\wsl-shell.exe

There is no `DefaultShellCommandOption` (uses the default `-c`, which wsl-shell.exe handles).

### 3. sshd_config change (SFTP subsystem)

The default `Subsystem sftp sftp-server.exe` points to the Windows SFTP server.
Since sshd runs subsystem commands through the default shell (wsl-shell.exe), this
tried to execute `sftp-server.exe` inside WSL's bash, which failed (exit 127).

Changed to:

    Subsystem sftp /usr/lib/openssh/sftp-server

This runs WSL's native sftp-server, so SCP/SFTP paths resolve as Linux paths
(`/home/...`, `/tmp/...`), not Windows paths.

Requires `openssh-sftp-server` package installed in WSL (`apt install openssh-sftp-server`).

## Restore steps after reinstall

1. Install OpenSSH Server: `Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0`
2. Copy `wsl-shell.exe` to `C:\ProgramData\ssh\`
3. Import `openssh_registry.reg` (double-click or `reg import openssh_registry.reg`)
4. Copy `sshd_config` to `C:\ProgramData\ssh\sshd_config` (has SFTP subsystem
   pointing to WSL's `/usr/lib/openssh/sftp-server`)
5. In WSL: `sudo apt install openssh-sftp-server` (if not already present)
6. Set up admin authorized_keys (required because admin users bypass `~/.ssh/authorized_keys`):
   ```
   Copy-Item C:\Users\francip\.ssh\id_rsa_personal.pub C:\ProgramData\ssh\administrators_authorized_keys
   icacls C:\ProgramData\ssh\administrators_authorized_keys /inheritance:r /grant "Administrators:F" /grant "SYSTEM:F"
   ```
7. Start the service: `Set-Service sshd -StartupType Automatic; Start-Service sshd`
8. Also start the agent: `Set-Service ssh-agent -StartupType Automatic; Start-Service ssh-agent`
9. Add key to agent (persists across reboots): `ssh-add C:\Users\francip\.ssh\id_rsa_personal`
10. Verify firewall rule exists: `Get-NetFirewallRule -DisplayName '*ssh*'`

## Claude Code statusline

A custom statusline script (`statusline-command.sh`) shows user, host, path, git
branch, model, and context usage — matching the shell prompt style.

### Apply steps

1. Copy the script:

       cp statusline-command.sh ~/.claude/statusline-command.sh

2. Add to `~/.claude/settings.json` (create if missing, merge if existing):

       {
         "statusLine": {
           "type": "command",
           "command": "bash ~/.claude/statusline-command.sh"
         }
       }

   If `settings.json` already exists, add the `"statusLine"` key to the existing
   object — don't overwrite other settings.

3. Restart Claude Code. The statusline appears at the bottom of the terminal.

### Requirements

- `node` on PATH (used for JSON parsing; guaranteed available since Claude Code is a Node.js app)
- `git` on PATH (for branch display)
- `cygpath` (ships with Git for Windows; used for Windows path display)

## Note on SSH clients

The Windows OpenSSH client (`C:\Windows\System32\OpenSSH\ssh.exe`) can access the
Windows ssh-agent service. Git Bash's SSH (`/usr/bin/ssh`) cannot, so it will fail
authentication if keys are only in the Windows agent.
