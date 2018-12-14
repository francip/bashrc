bashrc
======

The one bashrc to rule them all

To clone:

GIT_SSH_COMMAND='ssh -i ~/.ssh/id_rsa_personal' git clone ...

Mac OS X:

Install Homebrew or MacPorts

brew instal bash_completion
sudo port install bash-completion

Windows:

pacman -S git

Set MSYS=winsymlinks:nativestrict or CYGWIN=winsymlinks:nativestrict. This will change the behavior of
ln to use mklink and create native Windows symlinks.

WARNING: You need to run install.sh as administrator, as users don't have the permission to create symlinks.
(http://superuser.com/questions/124679/how-do-i-create-a-link-in-windows-7-home-premium-as-a-regular-user)

If the Windows user you are running msys under is not an administrator, run cmd.exe as administrator,
then run msys2 shell and then do 'export $HOME=/home/<username>' befor running the install.sh script

Also, the msys2 vim package comes without 'vi' alias, run cmd.ex as administrator and do in
/usr/bin 'ln -s vi vim.exe'

To share Windows and MSys2 home directories, add the following line to /etc/fstab and relogin to Windows
C:/Users /home ntfs binary,noacl,auto 1 1

CentOS

yum install bash-completion -y
