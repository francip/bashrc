# Future Improvements

## Performance
- Lazy-load nvm (biggest startup cost, ~200-500ms). Only initialize on first `nvm`/`node`/`npm` call
- Lazy-load conda hook (~200-400ms)
- Run `df` once instead of twice for free space (currently `-k` and `-h` separately)

## Architecture
- Extract shared code between bashrc and zshrc into a common `shrc_common` file. ~90% of both files is identical, every change has to be made twice (and twice the bugs)

## Replace pyenv with uv
- Remove pyenv blocks from bashrc and zshrc (saves ~100-200ms startup from two `eval` calls)
- Do this on the Ubuntu machine where pyenv-installed Python versions need to be migrated
- Reinstall Python versions via `uv python install`
- Update any `.python-version` files if needed (uv respects them)
- Remove pyenv and pyenv-virtualenv from the system after migration
- uv already handles versions, venvs, packages, and global tools — pyenv is redundant

## Cleanup
- iTerm2 shell integration — still needed? Ghostty terminfo fallback suggests a terminal switch happened
- ADB completion in bashrc — still doing Android dev from bash?
- `vcprompt` in bash PS1 — is this still installed anywhere?
- `which` usage in several places could be `command -v` (builtin, faster)
- `HISTSIZE=1000` is conservative — 10000+ is common in 2026

## SSH Agent
- No ssh-agent setup for macOS — relies on system agent, which isn't available over SSH without forwarding (the "Could not open a connection to your authentication agent" error on Tailscale SSH)
- Could skip `ssh-add` calls when no agent is reachable (check `ssh-add -l` exit code first)
