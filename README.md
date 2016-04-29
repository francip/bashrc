bashrc
======

The one bashrc to rule them all

Mac OS X:

Install Homebrew
brew instal bash_completion

Windows:

Set MSYS=winsymlinks:nativestrict or CYGWIN=winsymlinks:nativestrict. This will change the behavior of
ln to use mklink and create native Windows symlinks.

WARNING: You need to run install.sh as administrator, as users don't have the permission to create symlinks.
(http://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user)

If the Windows user you are running msys under is not an administrator, run cmd.exe as administrator,
then run msys2 shell and then do 'export $HOME=/home/<username>' befor running the install.sh script

Also, the msys2 vim package comes without 'vi' alias, run cmd.ex as administrator and do in
usr\bin 'mklink vi vim.exe'

# For msys2, add the following line to /etc/fstab and relogin
# C:\Users /home

CentOS

yum install bash-completion -y
