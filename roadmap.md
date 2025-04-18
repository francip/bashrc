# ZSH Configuration Roadmap

## 1. CDPATH and CD Behavior Fixes ✅

The main issue with ZSH's CDPATH handling was:

1. In ZSH, the `cdpath` variable needs to be converted from CDPATH string to array format
2. CDPATH setting was conditional on zsh-completions being installed
3. The `cd` function from aliases needs to be loaded after CDPATH is set

### Solution implemented:

1. Made CDPATH setup unconditional so it always runs
2. Added proper conversion from CDPATH to cdpath array:
   ```zsh
   # Convert CDPATH (colon separated string) to cdpath (array)
   cdpath=(${(s.:.)CDPATH})
   ```
3. Used the existing late-load mechanism in `__aliases_load` to ensure cd function is defined after CDPATH is set

## 2. Key Differences Between bashrc and zshrc

### Need to Port to zshrc

1. **Bash Prompt Configuration** ✅: 
   - Kept the default zsh prompt as oh-my-zsh will override it anyway
   - zsh theme is set to "amuse" in oh-my-zsh configuration

2. **Color Settings** ✅:
   - Added color settings for directories to zshrc
   - Matched the bash settings for both OSX and Linux

3. **Shell Variable Differences** ✅:
   - Added `SHELL` definition for Ubuntu in zshrc
   - Set to /usr/bin/env zsh (instead of bash)

4. **Tool-specific Completions** ✅:
   - Added simple git completion fallback if oh-my-zsh isn't used
   - Relies on oh-my-zsh's built-in git plugin for completions when available

5. **Go Path Configuration** ✅:
   - Fixed GOPATH in zshrc to use `$HOME/go` instead of `$HOME/src/Go`

## 3. Issues and Improvements

### Issues to Fix

1. **SSH Agent Configuration** ✅:
   - Fixed: Added interactive shell check for SSH-add in zshrc to match bashrc

2. **pgrep Command** ✅:
   - In bashrc, pgrep with `-u $USER` parameter (line 90)
   - Fixed: Added -u $USER parameter to pgrep commands in zshrc

3. **Bun Shell Integration** ✅:
   - Added Bun shell integration to bashrc to match zshrc configuration
   - Both shells now source the _bun integration file if available

4. **ZSH Completion** ✅:
   - Fixed: Replaced hardcoded user path with $HOME in Deno completions

5. **Conda Initialization** ✅:
   - Fixed: Replaced hardcoded user paths with $HOME in conda setup
   - Note: The implementations are different but both are generated by conda itself

### Improvements

1. **Configuration Structure**:
   - Consolidate common code between zshrc and bashrc into shared files
   - Create a common config format that both shells can source

2. **Feature Parity**:
   - Ensure all functions and aliases work identically in both shells
   - Document any intentional differences

3. **Error Handling**:
   - Add better error handling for missing directories or commands
   - Add fallback mechanisms for environment detection

4. **Performance**:
   - Profile shell startup time and optimize slow parts
   - Consider lazy-loading for rarely used functions

5. **Documentation**:
   - Add better commenting for ZSH-specific features
   - Document the purpose of each configuration section

## Implementation Timeline

1. **Immediate Fixes**:
   - Fix CDPATH and cd behavior in zshrc
   - Fix SSH agent configuration
   - Fix pgrep command in zshrc

2. **Short-term Improvements**:
   - Port prompt configuration from bashrc to zshrc
   - Standardize completion handling
   - Fix path settings (GOPATH, etc.)

3. **Long-term Refactoring**:
   - Create shared configuration system
   - Improve modularity and performance
   - Add comprehensive documentation