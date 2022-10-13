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
if ! [ -f $DOTNET_TOOLS/pwsh ]; then
  echo -e "\e[34mInstall PowerShell.\e[0m"
  dotnet tool update --global PowerShell
fi
if ! [ -f $DOTNET_TOOLS/dotnet-dump ]; then
  echo -e "\e[34mInstall .NET Dump.\e[0m"
  dotnet tool update --global dotnet-dump
fi
if ! [ -f $DOTNET_TOOLS/dotnet-gcdump ]; then
  echo -e "\e[34mInstall .NET GC Dump.\e[0m"
  dotnet tool update --global dotnet-gcdump
fi
if ! [ -f $DOTNET_TOOLS/dotnet-counters ]; then
  echo -e "\e[34mInstall .NET Counters.\e[0m"
  dotnet tool update --global dotnet-counters
fi
if ! [ -f $DOTNET_TOOLS/dotnet-trace ]; then
  echo -e "\e[34mInstall .NET Trace.\e[0m"
  dotnet tool update --global dotnet-trace
fi
if ! [ -f $DOTNET_TOOLS/dotnet-script ]; then
  echo -e "\e[34mInstall .NET Script.\e[0m"
  dotnet tool update --global dotnet-script
fi
if ! [ -f $DOTNET_TOOLS/dotnet-suggest ]; then
  echo -e "\e[34mInstall .NET Suggest.\e[0m"
  dotnet tool update --global dotnet-suggest
fi
if ! [ -f $DOTNET_TOOLS/tye ]; then
  echo -e "\e[34mInstall Tye.\e[0m"
  dotnet tool update --global Microsoft.Tye --prerelease
fi
if ! [ -f $DOTNET_TOOLS/dotnet-aspnet-codegenerator ]; then
  echo -e "\e[34mInstall ASP.NET Code Generator.\e[0m"
  dotnet tool update --global dotnet-aspnet-codegenerator
fi
if ! [ -f $DOTNET_TOOLS/dotnet-delice ]; then
  echo -e "\e[34mInstall Delice.\e[0m"
  dotnet tool update --global dotnet-delice
fi
if ! [ -f $DOTNET_TOOLS/dotnet-interactive ]; then
  echo -e "\e[34mInstall .NET Interactive.\e[0m"
  dotnet tool update --global Microsoft.dotnet-interactive
fi
if ! [ -f $DOTNET_TOOLS/dotnet-sos ]; then
  echo -e "\e[34mInstall .NET SOS.\e[0m"
  dotnet tool update --global dotnet-sos
fi
if ! [ -f $DOTNET_TOOLS/dotnet-symbol ] || ! [ -d $HOME/.dotnet/sos ]; then
  echo -e "\e[34mInstall .NET Symbol.\e[0m"
  dotnet tool update --global dotnet-symbol
  $HOME/.dotnet/tools/dotnet-sos install
fi
if ! [ -f $DOTNET_TOOLS/dotnet-try ]; then
  echo -e "\e[34mInstall .NET Try.\e[0m"
  dotnet tool update --global microsoft.dotnet-try
fi
if ! [ -f $DOTNET_TOOLS/httprepl ]; then
  echo -e "\e[34mInstall .NET HttpRepl.\e[0m"
  dotnet tool update --global Microsoft.dotnet-httprepl
fi
if ! [ -f $DOTNET_TOOLS/nukeeper ]; then
  echo -e "\e[34mInstall .NET Nukeeper.\e[0m"
  dotnet tool update --global nukeeper
fi
if ! [ -f $DOTNET_TOOLS/git-istage ]; then
  echo -e "\e[34mInstall Git Istage.\e[0m"
  dotnet tool update --global git-istage
fi

if $UPDATE; then
  for TOOL_NAME_AND_VERSION in `dotnet tool list --global | tail -n +3 | awk '{printf $1 ":"; print $2}'`; do
    TOOL_NAME=`echo $TOOL_NAME_AND_VERSION | cut -f1 -d':'`
    TOOL_VERSION=`echo $TOOL_NAME_AND_VERSION | cut -f2 -d':'`
    PRERELEASE=''
    if echo $TOOL_VERSION | grep --color=never '-' > /dev/null; then
      PRERELEASE='--prerelease'
    fi
    AVAILABLE_TOOL_VERSION=`dotnet tool search $TOOL_NAME $PRERELEASE | tail -n+3 | awk '{printf $1 ":"; print $2}' | grep "^$TOOL_NAME:" | cut -f2 -d':'`
    if [ "$TOOL_VERSION" != "$AVAILABLE_TOOL_VERSION" ]; then
      echo -e "\e[34mUpdating NET Tool $TOOL_NAME to $AVAILABLE_TOOL_VERSION.\e[0m"
      dotnet tool update --global $TOOL_NAME $PRERELEASE
    elif $VERBOSE; then
      echo -e "\e[34m.NET Tool $TOOL_NAME is version $AVAILABLE_TOOL_VERSION and does not need an update.\e[0m"
    fi
  done
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

# npm tools
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
trash-cli
typescript
vtop
yaml-cli" | sort`
NPM_PKGS_NOT_INSTALLED=`comm -23 <(echo "$NPM_PKGS_TO_INSTALL") <(echo "$NPM_PKGS_INSTALLED")`
if [ "$NPM_PKGS_NOT_INSTALLED" != "" ]; then
  echo -e "\e[34mInstall packages "$NPM_PKGS_NOT_INSTALLED" with npm.\e[0m"
  npm install -g $NPM_PKGS_NOT_INSTALLED
else
  if $UPDATE; then
    echo -e "\e[34mUpdating npm packages.\e[0m"
    npm update -g
  elif $VERBOSE; then
    echo "Not installing Npm packages, they are already installed."
  fi
fi
corepack enable # makes yarn available

# krew tools
if [ -e $HOME/.krew/bin/kubectl-krew ]; then
  if ! [[ $PATH =~ "$HOME/.krew/bin" ]]; then
    export PATH=$PATH:$HOME/.krew/bin
  fi
  if $UPDATE; then
    kubectl krew upgrade
  else
    kubectl krew install get-all resource-capacity sniff tail
  fi
else
  echo -e "\e[34mKrew not available, skipping...\e[0m"
fi

# gem/ruby
if [ -e $HOME/.rbenv/bin/rbenv ]; then
  if ! [[ $PATH =~ "$HOME/.rbenv/bin" ]]; then
    export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
  fi
  GEMS_INSTALLED=`gem list -q --no-versions`
  GEMS_TO_INSTALL="lolcat"
  GEMS_NOT_INSTALLED=`comm -23 <(echo "$GEMS_TO_INSTALL") <(echo "$GEMS_INSTALLED")`
  if [ "$GEMS_NOT_INSTALLED" != "" ]; then
    echo -e "\e[34mInstall gems "$GEMS_NOT_INSTALLED".\e[0m"
    gem install $GEMS_NOT_INSTALLED
  else
    if $VERBOSE; then
      echo "Not installing gems, they are already installed."
    fi
  fi
else
  echo -e "\e[34mRbenv not available, skipping...\e[0m"
fi

if [ -f $HOME/.cargo/env ]; then
  source "$HOME/.cargo/env"
  # rust/cargo
  CRATES_INSTALLED=`cargo install --list | cut -f1 -d' ' | awk 'NF'`
  # todo: how to work with as-tree, which is not on crates.io?
  # See issue: https://github.com/jez/as-tree/issues/14
  CRATES_TO_INSTALL="cargo-update
  cargo-edit
  cargo-expand
  cargo-outdated
  cargo-watch
  cross
  du-dust
  fd-find
  gping
  grex
  just
  navi
  procs
  ripgrep
  sccache
  tealdeer
  tokei"
  CRATES_TO_INSTALL_NO_LOCK="bandwhich" # see https://github.com/imsnif/bandwhich/issues/258
  CRATES_NOT_INSTALLED=`comm -23 <(sort <(echo "$CRATES_TO_INSTALL")) <(sort <(echo "$CRATES_INSTALLED"))`
  if [ "$CRATES_NOT_INSTALLED" != "" ]; then
    echo -e "\e[34mInstall crates $CRATES_NOT_INSTALLED.\e[0m"
    cargo install --locked $CRATES_NOT_INSTALLED
  else
    if $VERBOSE; then
      echo "Not installing crates, they are already installed."
    fi
  fi
  CRATES_NOT_INSTALLED_NO_LOCK=`comm -23 <(sort <(echo "$CRATES_TO_INSTALL")) <(sort <(echo "$CRATES_TO_INSTALL_NO_LOCK"))`
  if [ "$CRATES_NOT_INSTALLED_NO_LOCK" != "" ]; then
    echo -e "\e[34mInstall crates $CRATES_NOT_INSTALLED_NO_LOCK.\e[0m"
    cargo install $CRATES_NOT_INSTALLED_NO_LOCK
  else
    if $VERBOSE; then
      echo "Not installing crates, they are already installed."
    fi
  fi
  if $UPDATE; then
    cargo install-update -a
  fi
fi

if [ -e $HOME/.go/bin/go ]; then
  export PATH=$PATH:$HOME/.go/bin
  go install github.com/mitchellh/gox@latest
fi
