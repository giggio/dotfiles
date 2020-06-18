#!/usr/bin/env bash

set -euo pipefail

UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  key="$1"
  case $key in
    --update|-u)
    UPDATE=true
    shift
    ;;
    --help|-h)
    SHOW_HELP=true
    break
    ;;
    --verbose)
    VERBOSE=true
    shift
    ;;
    *)
    shift
    ;;
  esac
done

if $SHOW_HELP; then
  cat <<EOF
Post installer.

Usage:
  `readlink -f $0` [flags]

Flags:
  -u, --update                                       Will download and install/reinstall even if the tools are already installed
      --verbose                                      Show verbose output
  -h, --help                                         This help
EOF
  exit 0
fi

if $VERBOSE; then
  echo Running `basename "$0"` $ALL_ARGS
  echo Update is $UPDATE
fi

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
echo -e "\e[34mInstalling other packages.\e[0m"
sudo -E $BASEDIR/install-pkgs.sh

echo -e "\e[34mCleanning up packages.\e[0m"
sudo apt-get autoremove -y

if ! [[ `locale -a` =~ 'en_US.utf8' ]]; then
  echo -e "\e[34mGenerate location.\e[0m"
  sudo locale-gen en_US.UTF-8
fi

PIP_PKGS_INSTALLED=`pip3 list --user --format columns | tail -n +3 | awk '{print $1}'`
PIP_PKGS_TO_INSTALL="powerline-status
xlsx2csv"
PIP_PKGS_NOT_INSTALLED=`comm -23 <(echo "$PIP_PKGS_TO_INSTALL") <(echo "$PIP_PKGS_INSTALLED")`
if [ "$PIP_PKGS_NOT_INSTALLED" != "" ]; then
  echo -e "\e[34mInstall packages "$PIP_PKGS_NOT_INSTALLED" with Pip.\e[0m"
  pip3 install --user $PIP_PKGS_NOT_INSTALLED
fi

# pwsh
echo -e "\e[34mInstall several packages with .NET.\e[0m"
DOTNET_TOOLS=$HOME/.dotnet/tools
if ! [ -f $DOTNET_TOOLS/pwsh ] || $UPDATE; then
  dotnet tool update --global PowerShell
fi
if ! [ -f $DOTNET_TOOLS/dotnet-dump ] || $UPDATE; then
  dotnet tool update --global dotnet-dump
fi
if ! [ -f $DOTNET_TOOLS/dotnet-gcdump ] || $UPDATE; then
  dotnet tool update --global dotnet-gcdump
fi
if ! [ -f $DOTNET_TOOLS/dotnet-counters ] || $UPDATE; then
  dotnet tool update --global dotnet-counters
fi
if ! [ -f $DOTNET_TOOLS/dotnet-trace ] || $UPDATE; then
  dotnet tool update --global dotnet-trace
fi
if ! [ -f $DOTNET_TOOLS/dotnet-script ] || $UPDATE; then
  dotnet tool update --global dotnet-script
fi
if ! [ -f $DOTNET_TOOLS/dotnet-suggest ] || $UPDATE; then
  dotnet tool update --global dotnet-suggest
fi
if ! [ -f $DOTNET_TOOLS/tye ] || $UPDATE; then
  dotnet tool update --global Microsoft.Tye --version "0.2.0-alpha.20258.3"
fi
if ! [ -f $DOTNET_TOOLS/dotnet-aspnet-codegenerator ] || $UPDATE; then
  dotnet tool update --global dotnet-aspnet-codegenerator
fi
if ! [ -f $DOTNET_TOOLS/dotnet-delice ] || $UPDATE; then
  dotnet tool update --global dotnet-delice
fi
if ! [ -f $DOTNET_TOOLS/dotnet-interactive ] || $UPDATE; then
  dotnet tool update --global Microsoft.dotnet-interactive
fi
if ! [ -f $DOTNET_TOOLS/dotnet-sos ] || $UPDATE; then
  dotnet tool update --global dotnet-sos
fi
if ! [ -f $DOTNET_TOOLS/dotnet-symbol ] || ! [ -d $HOME/.dotnet/sos ] || $UPDATE; then
  dotnet tool update --global dotnet-symbol
  $HOME/.dotnet/tools/dotnet-sos install
fi
if ! [ -f $DOTNET_TOOLS/dotnet-try ] || $UPDATE; then
  dotnet tool update --global dotnet-try
fi
if ! [ -f $DOTNET_TOOLS/httprepl ] || $UPDATE; then
  dotnet tool update --global Microsoft.dotnet-httprepl
fi
if ! [ -f $DOTNET_TOOLS/nukeeper ] || $UPDATE; then
  dotnet tool update --global nukeeper
fi
if ! [ -f $DOTNET_TOOLS/git-istage ] || $UPDATE; then
  dotnet tool update --global git-istage
fi

# node
export N_PREFIX=$HOME/.n
if ! hash node 2>/dev/null && ! [ -f $HOME/.n/bin/node ] || $UPDATE; then
  echo -e "\e[34mInstall Install latest Node version through n.\e[0m"
  $BASEDIR/tools/n/bin/n install latest
fi
export PATH="$N_PREFIX/bin:$PATH"
#npm tools
export NG_CLI_ANALYTICS=ci
# NPM_PKGS_INSTALLED=$(npm list -g --depth=0 --parseable | tail -n +2 | sed 's|'`npm prefix -g`'/lib/node_modules/||g')
# NPM_PKGS_INSTALLED_ORGS=$(ls -d `npm prefix -g`/lib/node_modules/* | grep --color=never @)
NPM_PKGS_INSTALLED_NOT_ORGS=$(ls `npm prefix -g`/lib/node_modules | grep -v @)
NPM_PKGS_INSTALLED_ORGS=''
for ORG_DIR in $(ls -d `npm prefix -g`/lib/node_modules/* | grep --color=never @); do
  for PKG in `ls $ORG_DIR`; do
    NPM_PKGS_INSTALLED_ORGS+=$'\n'`basename $ORG_DIR`/$PKG
  done
done
NPM_PKGS_INSTALLED_ORGS=`echo "$NPM_PKGS_INSTALLED_ORGS" | tail -n +2`
NPM_PKGS_INSTALLED=`echo "$NPM_PKGS_INSTALLED_NOT_ORGS"$'\n'"$NPM_PKGS_INSTALLED_ORGS" | sort`
NPM_PKGS_TO_INSTALL=`echo "@angular/cli
bash-language-server
bats
bower
cross-env
diff-so-fancy
eslint
express-generator
gist-cli
gitignore
glob-tester-cli
grunt-cli
gulp
http-server
karma-cli
license-checker
loadtest
madge
mocha
nodemon
npmrc
pm2
tldr
trash-cli
typescript
vtop
yaml-cli
yarn" | sort`
NPM_PKGS_NOT_INSTALLED=`comm -23 <(echo "$NPM_PKGS_TO_INSTALL") <(echo "$NPM_PKGS_INSTALLED")`
if [ "$NPM_PKGS_NOT_INSTALLED" != "" ]; then
  echo -e "\e[34mInstall packages "$NPM_PKGS_NOT_INSTALLED" with npm.\e[0m"
  npm install -g $NPM_PKGS_NOT_INSTALLED
fi

# deno
if ! hash deno 2>/dev/null && ! [ -f $HOME/.deno/bin/deno ] || $UPDATE; then
  echo -e "\e[34mInstall Deno.\e[0m"
  curl -fsSL https://deno.land/x/install/install.sh | sh
fi

# k9s
if ! hash k9s 2>/dev/null || $UPDATE; then
  echo -e "\e[34mInstall k9s.\e[0m"
  wget https://github.com/derailed/k9s/releases/download/v0.20.5/k9s_Linux_arm.tar.gz -O /tmp/k9s.tar.gz
  mkdir /tmp/k9s/
  tar -xvzf /tmp/k9s.tar.gz -C /tmp/k9s/
  sudo mv /tmp/k9s/k9s /usr/local/bin/
  rm -rf /tmp/k9s/
  rm /tmp/k9s.tar.gz
fi

# rbenv
if ! hash rbenv 2>/dev/null && ! [ -f $HOME/.rbenv/bin/rbenv ] || $UPDATE; then
  echo -e "\e[34mInstall ruby-build and install Ruby with rbenv.\e[0m"
  git clone https://github.com/rbenv/ruby-build.git $BASEDIR/tools/rbenv/plugins/ruby-build
  $HOME/.rbenv/bin/rbenv install 2.7.1
  $HOME/.rbenv/bin/rbenv global 2.7.1
fi

if ! [ -f /etc/sudoers.d/10-cron ]; then
  echo -e "\e[34mAllow cron to start without su.\e[0m"
  echo "#allow cron to start without su
%sudo ALL=NOPASSWD: /etc/init.d/cron start" | sudo tee /etc/sudoers.d/10-cron
  sudo chmod 440 /etc/sudoers.d/10-cron
fi

function setAlternative() {
  NAME=$1
  EXEC_PATH=`which $2`
  if [ `update-alternatives --display $NAME | sed -n 's/.*link currently points to \(.*\)$/\1/p'` != $EXEC_PATH ]; then
    sudo update-alternatives --set $NAME $EXEC_PATH
  fi
}

if $WSL; then
  if hash wslview 2>/dev/null; then
    setAlternative x-www-browser wslview
  fi
fi

setAlternative editor /usr/bin/vim.basic
