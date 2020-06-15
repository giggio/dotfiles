#!/usr/bin/env bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "\e[34mInstalling other packages.\e[0m"
sudo bash $BASEDIR/install-pkgs.sh

echo -e "\e[34mCleanning up packages.\e[0m"
sudo apt-get autoremove -y

echo -e "\e[34mGenerate location.\e[0m"
sudo locale-gen en_US.UTF-8

echo -e "\e[34mInstall powerline-status through pip.\e[0m"
pip3 install --user powerline-status

# pwsh
echo -e "\e[34mInstall PowerShell through .NET cli.\e[0m"
dotnet tool update --global PowerShell
dotnet tool update --global dotnet-dump
dotnet tool update --global dotnet-gcdump
dotnet tool update --global dotnet-counters
dotnet tool update --global dotnet-trace
dotnet tool update --global dotnet-script
dotnet tool update --global dotnet-suggest
dotnet tool update --global Microsoft.Tye --version "0.2.0-alpha.20258.3"
dotnet tool update --global dotnet-aspnet-codegenerator
dotnet tool update --global dotnet-delice
dotnet tool update --global Microsoft.dotnet-interactive
dotnet tool update --global dotnet-sos
dotnet tool update --global dotnet-symbol
$HOME/.dotnet/tools/dotnet-sos install
dotnet tool update --global dotnet-try
dotnet tool update --global Microsoft.dotnet-httprepl
dotnet tool update --global nukeeper
dotnet tool update --global git-istage

# node
echo -e "\e[34mInstall Install latest Node version through n.\e[0m"
export N_PREFIX=$HOME/.n
$BASEDIR/bashscripts/bin/n install latest
export PATH="$N_PREFIX/bin:$PATH"
#npm tools
echo -e "\e[34mInstall several packages with npm.\e[0m"
export NG_CLI_ANALYTICS=ci
npm install -g \
  @angular/cli \
  bash-language-server \
  bats \
  bower \
  cross-env \
  diff-so-fancy \
  eslint \
  express-generator \
  gist-cli \
  gitignore \
  glob-tester-cli \
  grunt-cli \
  gulp \
  http-server \
  karma-cli \
  license-checker \
  loadtest \
  madge \
  mocha \
  nodemon \
  npmrc \
  pm2 \
  tldr \
  trash-cli \
  typescript \
  vtop \
  yaml-cli \
  yarn

# deno
echo -e "\e[34mInstall Deno.\e[0m"
curl -fsSL https://deno.land/x/install/install.sh | sh

# k9s
wget https://github.com/derailed/k9s/releases/download/v0.20.5/k9s_Linux_arm.tar.gz -O /tmp/k9s.tar.gz
mkdir /tmp/k9s/
tar -xvzf /tmp/k9s.tar.gz -C /tmp/k9s/
sudo mv /tmp/k9s/k9s /usr/local/bin/
rm -rf /tmp/k9s/
rm /tmp/k9s.tar.gz

# rbenv
echo -e "\e[34mInstall ruby-build and install Ruby with rbenv.\e[0m"
git clone https://github.com/rbenv/ruby-build.git $BASEDIR/rbenv/plugins/ruby-build
$HOME/.rbenv/bin/rbenv install 2.7.1
$HOME/.rbenv/bin/rbenv global 2.7.1

echo -e "\e[34mAllow cron to start without su.\e[0m"
if ! [ -f /etc/sudoers.d/10-cron ]; then
    echo "#allow cron to start without su
%sudo ALL=NOPASSWD: /etc/init.d/cron start" | sudo tee /etc/sudoers.d/10-cron
    sudo chmod 440 /etc/sudoers.d/10-cron
fi

echo -e "\e[34mSet vim as the default editor for `whoami` and root.\e[0m"
sudo update-alternatives --set editor /usr/bin/vim.basic
update-alternatives --set editor /usr/bin/vim.basic
