bashrc
======

The one bashrc to rule them all

Prerequisites:
 - Homebrew for Mac OS X
   brew instal bash_completion
   ln -s /usr/local/Library/Contributions/brew_bash_completion.sh /usr/local/etc/bash_completion.d
 - git_completion.bash - either brew install git or copy from SourceTree
 - adb.bash - copy from AOSP

Windows:
You can't run install.sh on Windows, as it will copy the files, not create symlinks. Try the following
suggestion, and if it works, use mklink.exe to create the links.

http://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user
