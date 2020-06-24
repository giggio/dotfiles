#!/bin/bash

set -euo pipefail

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ "$EUID" == "0" ]; then
  echo "Please do not run this script as root"
  exit 2
fi

ALL_ARGS=$@
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
Install platform tools (.NET tools, Npm tools, Pip tools etc).

Usage:
  `readlink -f $0` [flags]

Flags:
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  echo -e "\e[32mRunning `basename "$0"` $ALL_ARGS\e[0m"
  echo Update is $UPDATE
fi

PIP_PKGS_INSTALLED=`pip3 list --user --format columns | tail -n +3 | awk '{print $1}'`
PIP_PKGS_TO_INSTALL="powerline-status
xlsx2csv"
PIP_PKGS_NOT_INSTALLED=`comm -23 <(echo "$PIP_PKGS_TO_INSTALL") <(echo "$PIP_PKGS_INSTALLED")`
if [ "$PIP_PKGS_NOT_INSTALLED" != "" ]; then
  echo -e "\e[34mInstall packages "$PIP_PKGS_NOT_INSTALLED" with Pip.\e[0m"
  pip3 install --user $PIP_PKGS_NOT_INSTALLED
else
  if $VERBOSE; then
    echo "Not installing Pip packages, they are already installed."
  fi
fi

# .NET Tools
DOTNET_TOOLS=$HOME/.dotnet/tools
if ! [ -f $DOTNET_TOOLS/pwsh ] || $UPDATE; then
  echo -e "\e[34mInstall PowerShell.\e[0m"
  dotnet tool update --global PowerShell
fi
if ! [ -f $DOTNET_TOOLS/dotnet-dump ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Dump.\e[0m"
  dotnet tool update --global dotnet-dump
fi
if ! [ -f $DOTNET_TOOLS/dotnet-gcdump ] || $UPDATE; then
  echo -e "\e[34mInstall .NET GC Dump.\e[0m"
  dotnet tool update --global dotnet-gcdump
fi
if ! [ -f $DOTNET_TOOLS/dotnet-counters ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Counters.\e[0m"
  dotnet tool update --global dotnet-counters
fi
if ! [ -f $DOTNET_TOOLS/dotnet-trace ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Trace.\e[0m"
  dotnet tool update --global dotnet-trace
fi
if ! [ -f $DOTNET_TOOLS/dotnet-script ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Script.\e[0m"
  dotnet tool update --global dotnet-script
fi
if ! [ -f $DOTNET_TOOLS/dotnet-suggest ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Suggest.\e[0m"
  dotnet tool update --global dotnet-suggest
fi
if ! [ -f $DOTNET_TOOLS/tye ] || $UPDATE; then
  echo -e "\e[34mInstall Tye.\e[0m"
  dotnet tool update --global Microsoft.Tye --version "0.3.0-alpha.20319.3"
fi
if ! [ -f $DOTNET_TOOLS/dotnet-aspnet-codegenerator ] || $UPDATE; then
  echo -e "\e[34mInstall ASP.NET Code Generator.\e[0m"
  dotnet tool update --global dotnet-aspnet-codegenerator
fi
if ! [ -f $DOTNET_TOOLS/dotnet-delice ] || $UPDATE; then
  echo -e "\e[34mInstall Delice.\e[0m"
  dotnet tool update --global dotnet-delice
fi
if ! [ -f $DOTNET_TOOLS/dotnet-interactive ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Interactive.\e[0m"
  dotnet tool update --global Microsoft.dotnet-interactive
fi
if ! [ -f $DOTNET_TOOLS/dotnet-sos ] || $UPDATE; then
  echo -e "\e[34mInstall .NET SOS.\e[0m"
  dotnet tool update --global dotnet-sos
fi
if ! [ -f $DOTNET_TOOLS/dotnet-symbol ] || ! [ -d $HOME/.dotnet/sos ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Symbol.\e[0m"
  dotnet tool update --global dotnet-symbol
  $HOME/.dotnet/tools/dotnet-sos install
fi
if ! [ -f $DOTNET_TOOLS/dotnet-try ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Try.\e[0m"
  dotnet tool update --global dotnet-try
fi
if ! [ -f $DOTNET_TOOLS/httprepl ] || $UPDATE; then
  echo -e "\e[34mInstall .NET HttpRepl.\e[0m"
  dotnet tool update --global Microsoft.dotnet-httprepl
fi
if ! [ -f $DOTNET_TOOLS/nukeeper ] || $UPDATE; then
  echo -e "\e[34mInstall .NET Nukeeper.\e[0m"
  dotnet tool update --global nukeeper
fi
if ! [ -f $DOTNET_TOOLS/git-istage ] || $UPDATE; then
  echo -e "\e[34mInstall Git Istage.\e[0m"
  dotnet tool update --global git-istage
fi

# node
export N_PREFIX=$HOME/.n
if ! hash node 2>/dev/null && ! [ -f $HOME/.n/bin/node ] || $UPDATE; then
  echo -e "\e[34mInstall Install latest Node version through n.\e[0m"
  $BASEDIR/tools/n/bin/n install latest
else
  if $VERBOSE; then
    echo "Not installing latest Node.js version."
  fi
fi
export PATH="$N_PREFIX/bin:$PATH"
#npm tools
export NG_CLI_ANALYTICS=ci
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
if [ "$NPM_PKGS_NOT_INSTALLED" != "" ] || $UPDATE; then
  echo -e "\e[34mInstall packages "$NPM_PKGS_NOT_INSTALLED" with npm.\e[0m"
  npm install -g $NPM_PKGS_NOT_INSTALLED
else
  if $VERBOSE; then
    echo "Not installing Npm packages, they are already installed."
  fi
fi
