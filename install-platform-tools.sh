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
elif $UPDATE; then
  PIP_OUTDATED=`pip3 list --user --format columns --outdated | tail -n +3 | awk '{print $1}'`
  if [ "$PIP_OUTDATED" != '' ]; then
    echo -e "\e[34mUpdate packages "$PIP_OUTDATED" with Pip.\e[0m"
    pip3 install --user --upgrade $PIP_OUTDATED
  fi
else
  if $VERBOSE; then
    echo -e "\e[34mNot installing Pip packages, they are already installed.\e[0m"
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
    AVAILABLE_TOOL_VERSION=`dotnet tool search $TOOL_NAME $PRERELEASE | tail -n+3 | awk '{printf $1 ":"; print $2}' | (grep --color=never "^$TOOL_NAME:" || echo "$TOOL_NAME:") | cut -f2 -d':'`
    if [ "$AVAILABLE_TOOL_VERSION" == '' ]; then
      echo -e "\e[34mTool $TOOL_NAME seems to have changed names, installing the new one and uninstalling the old one.\e[0m"
      dotnet tool uninstall -g $TOOL_NAME
      dotnet tool update --global `dotnet tool search $TOOL_NAME | tail -n+3 | awk '{print $1}'`
    elif [ "$TOOL_VERSION" != "$AVAILABLE_TOOL_VERSION" ]; then
      echo -e "\e[34mUpdating NET Tool $TOOL_NAME to $AVAILABLE_TOOL_VERSION.\e[0m"
      dotnet tool update --global $TOOL_NAME $PRERELEASE
    elif $VERBOSE; then
      echo -e "\e[34m.NET Tool $TOOL_NAME is version $AVAILABLE_TOOL_VERSION and does not need an update.\e[0m"
    fi
  done
fi

# node
export N_PREFIX=$HOME/.n
if ! hash node 2>/dev/null && ! [ -f $HOME/.n/bin/node ]; then
  echo -e "\e[34mInstall Install latest Node version through n.\e[0m"
  $BASEDIR/tools/n/bin/n install latest
elif $UPDATE; then
  LATEST_NODE=`n ls-remote | head -n 2 | tail -n 1`
  if ! echo "`$BASEDIR/tools/n/bin/n ls`" | grep --color=never $LATEST_NODE -q; then
    echo -e "\e[34mInstall Install latest Node version through n.\e[0m"
    $BASEDIR/tools/n/bin/n install latest
  fi
else
  if $VERBOSE; then
    echo -e "\e[34mNot installing Node.js version.\e[0m"
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
bats-assert
bats-support
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
    if [ "`npm outdated -g`" != '' ]; then
      echo -e "\e[34mUpdating npm packages.\e[0m"
      npm update -g
    else
      if $VERBOSE; then
        echo -e "\e[34mNot installing Npm packages, they are already up to date.\e[0m"
      fi
    fi
  elif $VERBOSE; then
    echo -e "\e[34mNot installing Npm packages, they are already installed.\e[0m"
  fi
fi
corepack enable # makes yarn available

# krew tools
if [ -e $HOME/.krew/bin/kubectl-krew ]; then
  if ! [[ $PATH =~ "$HOME/.krew/bin" ]]; then
    export PATH=$PATH:$HOME/.krew/bin
  fi
  if $UPDATE; then
    echo -e "\e[34mUpdating Krew plugins.\e[0m"
    kubectl krew upgrade
  else
    KREW_PLUGINS_INSTALLED=`kubectl krew list | tail -n+1 | awk '{print $1}' | sort -u`
    KREW_PLUGINS_TO_INSTALL=`echo "get-all
resource-capacity
sniff
tail" | sort`
    KREW_PLUGINS_NOT_INSTALLED=`comm -23 <(echo "$KREW_PLUGINS_TO_INSTALL") <(echo "$KREW_PLUGINS_INSTALLED")`
    if [ "$KREW_PLUGINS_NOT_INSTALLED" != "" ]; then
      echo -e "\e[34mInstalling Krew plugins: $KREW_PLUGINS_NOT_INSTALLED\e[0m"
      kubectl krew install $KREW_PLUGINS_NOT_INSTALLED
    elif $VERBOSE; then
      echo -e "\e[34mNot installing krew plugins, they are already installed.\e[0m"
    fi
  fi
else
  echo -e "\e[34mKrew not available, skipping...\e[0m"
fi

# gem/ruby
if [ -e $HOME/.rbenv/bin/rbenv ]; then
  if ! [[ $PATH =~ "$HOME/.rbenv/bin" ]]; then
    export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
  fi
  GEMS_INSTALLED=`gem list -q --no-versions | sort`
  GEMS_TO_INSTALL="lolcat"
  GEMS_NOT_INSTALLED=`comm -23 <(echo "$GEMS_TO_INSTALL") <(echo "$GEMS_INSTALLED")`
  if [ "$GEMS_NOT_INSTALLED" != "" ]; then
    echo -e "\e[34mInstall gems "$GEMS_NOT_INSTALLED".\e[0m"
    gem install $GEMS_NOT_INSTALLED
  else
    if $VERBOSE; then
      echo -e "\e[34mNot installing gems, they are already installed.\e[0m"
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
      echo -e "\e[34mNot installing crates, they are already installed.\e[0m"
    fi
  fi
  CRATES_NOT_INSTALLED_NO_LOCK=`comm -23 <(sort <(echo "$CRATES_TO_INSTALL_NO_LOCK")) <(sort <(echo "$CRATES_INSTALLED"))`
  if [ "$CRATES_NOT_INSTALLED_NO_LOCK" != "" ]; then
    echo -e "\e[34mInstall crates $CRATES_NOT_INSTALLED_NO_LOCK without --locked.\e[0m"
    cargo install $CRATES_NOT_INSTALLED_NO_LOCK
  else
    if $VERBOSE; then
      echo -e "\e[34mNot installing crates without --locked, they are already installed.\e[0m"
    fi
  fi
  if $UPDATE; then
    echo -e "\e[34mUpdating crates.\e[0m"
    cargo install-update -a
  fi
fi

if [ -e $HOME/.go/bin/go ]; then
  export PATH=$PATH:$HOME/.go/bin
  if $UPDATE; then
    echo -e "\e[34mInstalling/updating go packages.\e[0m"
  fi
  if ! hash gox 2>/dev/null || $UPDATE; then
    go install github.com/mitchellh/gox@latest
  fi
fi
