#!/usr/bin/env bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "\e[34mInstalling other packages.\e[0m"
sudo bash $BASEDIR/install-pkgs.sh

echo -e "\e[34mCleanning up packages.\e[0m"
sudo apt-get autoremove -y

sudo locale-gen en_US.UTF-8

pip3 install --user powerline-status

# pwsh
dotnet tool install --global PowerShell

# node
export N_PREFIX=$HOME/.n
$BASEDIR/bashscripts/bin/n install latest
export PATH="$N_PREFIX/bin:$PATH"
#npm tools
npm install -g trash-cli bash-language-server gist-cli vtop yaml-cli yarn

# rbenv
git clone https://github.com/rbenv/ruby-build.git $BASEDIR/rbenv/plugins/ruby-build
rbenv install 2.7.1
rbenv global 2.7.1

if ! [ -f /etc/sudoers.d/10-cron ]; then
    echo "#allow cron to start without su
%sudo ALL=NOPASSWD: /etc/init.d/cron start" | sudo tee /etc/sudoers.d/10-cron
    sudo chmod 440 /etc/sudoers.d/10-cron
fi

sudo update-alternatives --set editor /usr/bin/vim.basic
update-alternatives --set editor /usr/bin/vim.basic
