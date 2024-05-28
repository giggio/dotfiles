# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
  # include .bashrc if it exists
  if [ -f "$HOME/.bashrc" ]; then
	source "$HOME/.bashrc"
  fi
fi

# set PATH so it includes user's private bin directories
PATH="$HOME/bin:$HOME/.local/bin:$PATH"

# setup n in .profile so it is picked up by all shells and desktop environments
N_PREFIX=$HOME/.n
if [ -d "$N_PREFIX" ]; then
  export PATH=$N_PREFIX/bin:$PATH
  export N_PREFIX
fi

# if we don't add it to the .profile, it will be set to 500 for login shells
HISTSIZE=-1
HISTFILESIZE=-1
# see https://superuser.com/questions/575479/bash-history-truncated-to-500-lines-on-each-login
HISTFILE=~/.bash_history2
