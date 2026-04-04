# Future Improvements

## Performance
- Lazy-load nvm (biggest startup cost, ~200-500ms). Only initialize on first `nvm`/`node`/`npm` call
- Lazy-load conda hook (~200-400ms)
- Run `df` once instead of twice for free space (currently `-k` and `-h` separately)

## Architecture
- Extract shared code between bashrc and zshrc into a common `shrc_common` file. ~90% of both files is identical, every change has to be made twice (and twice the bugs)

## Cleanup
- `which` usage in several places could be `command -v` (builtin, faster)

## SSH Agent
- Could skip `ssh-add` calls when no agent is reachable (check `ssh-add -l` exit code first)
