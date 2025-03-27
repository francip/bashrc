#!/bin/zsh
# Test CDPATH behavior in zsh

echo "SHELL: $SHELL"
echo "CDPATH: $CDPATH"
echo "cdpath: ${cdpath[@]}"

# Test cd function
if typeset -f cd > /dev/null; then
    echo "Found cd function:"
    typeset -f cd
else
    echo "No cd function found, using builtin"
fi

# Start from home directory
cd $HOME
echo "Starting from: $(pwd)"

# Test changing to a directory in CDPATH without path
echo "Trying to cd to a directory in CDPATH without path..."
cd src 2>&1
echo "Current directory: $(pwd)"

# Reset
cd $HOME
echo "Reset to: $(pwd)"

# Test using subdirectory in CDPATH
if [[ -d $HOME/src/bashrc ]]; then
    echo "Trying to cd to a subdirectory of a CDPATH entry..."
    cd bashrc 2>&1
    echo "Current directory: $(pwd)"
    
    # Reset
    cd $HOME
    echo "Reset to: $(pwd)"
    
    # Try with full CDPATH search
    echo "Trying cd with just the subdirectory name..."
    cd bashrc 2>&1
    echo "Current directory: $(pwd)"
fi

# Test autocompletion
echo ""
echo "To test autocompletion, run: cd ba<TAB>"
echo "It should complete to 'cd bashrc' if CDPATH is working correctly"