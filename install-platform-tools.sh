#!/usr/bin/env bash

BASEDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$BASEDIR"/_common-setup.sh

if [ "$EUID" == "0" ] && ! $ANDROID; then
  die "Please do not run this script as root"
fi

BASIC_SETUP=false
UPDATE=false
SHOW_HELP=false
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --basic|-b)
    BASIC_SETUP=true
    shift
    ;;
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
eval set -- "$PARSED_ARGS"

if $SHOW_HELP; then
  cat <<EOF
Install platform tools (.NET tools, Npm tools, Pip tools etc).

Usage:
  `readlink -f "$0"` [flags]

Flags:
  -b, --basic              Will only install basic packages to get Bash working
  -u, --update             Will download and install/reinstall even if the tools are already installed
      --verbose            Show verbose output
  -h, --help               help
EOF
  exit 0
fi

if $VERBOSE; then
  writeGreen "Running `basename "$0"` $ALL_ARGS
  Update is $UPDATE
  Basic setup is $BASIC_SETUP"
fi

PIP_PKGS_INSTALLED=`pip3 list --user --format columns | tail -n +3 | awk '{print $1}'`
PIP_BASIC_PKGS_TO_INSTALL="powerline-status"
PIP_PKGS_TO_INSTALL="xlsx2csv"
if $BASIC_SETUP; then
  PIP_PKGS_TO_INSTALL=$PIP_BASIC_PKGS_TO_INSTALL
else
  PIP_PKGS_TO_INSTALL=`echo "$PIP_BASIC_PKGS_TO_INSTALL"$'\n'"$PIP_PKGS_TO_INSTALL" | sort`
fi
PIP_PKGS_NOT_INSTALLED=`comm -23 <(echo "$PIP_PKGS_TO_INSTALL") <(echo "$PIP_PKGS_INSTALLED")`
if [ "$PIP_PKGS_NOT_INSTALLED" != "" ]; then
  # shellcheck disable=SC2086
  writeBlue Install packages $PIP_PKGS_NOT_INSTALLED with Pip.
  # shellcheck disable=SC2086
  pip3 install --user $PIP_PKGS_NOT_INSTALLED
else
  if $VERBOSE; then
    writeBlue "Not installing Pip packages, they are already installed."
  fi
fi
if $UPDATE; then
  PIP_OUTDATED=`pip3 list --user --format columns --outdated | tail -n +3 | awk '{print $1}'`
  if [ "$PIP_OUTDATED" != '' ]; then
    # shellcheck disable=SC2086
    writeBlue Update packages $PIP_OUTDATED with Pip.
    # shellcheck disable=SC2086
    pip3 install --user --upgrade $PIP_OUTDATED
  else
    writeBlue "Not updating Pip packages, they are already up to date."
  fi
fi

if $BASIC_SETUP; then
  exit
fi

# .NET Tools
DOTNET_TOOLS_DIR=$HOME/.dotnet/tools
declare -A DOTNET_TOOLS=(
  ["dotnet-aspnet-codegenerator"]="dotnet-aspnet-codegenerator"
  ["dotnet-counters"]="dotnet-counters"
  ["dotnet-delice"]="dotnet-delice"
  ["dotnet-dump"]="dotnet-dump"
  ["dotnet-gcdump"]="dotnet-gcdump"
  ["dotnet-interactive"]="Microsoft.dotnet-interactive"
  ["dotnet-script"]="dotnet-script"
  ["dotnet-sos"]="dotnet-sos"
  ["dotnet-suggest"]="dotnet-suggest"
  ["dotnet-trace"]="dotnet-trace"
  ["dotnet-try"]="microsoft.dotnet-try"
  ["git-istage"]="git-istage"
  ["httprepl"]="Microsoft.dotnet-httprepl"
  ["nukeeper"]="nukeeper"
  ["pwsh"]="PowerShell"
)
for DOTNET_TOOL in "${!DOTNET_TOOLS[@]}"; do
  if ! [ -f "$DOTNET_TOOLS_DIR/$DOTNET_TOOL" ]; then
    writeBlue "Install .NET tool $DOTNET_TOOL (${DOTNET_TOOLS[$DOTNET_TOOL]})."
    dotnet tool update --global "${DOTNET_TOOLS[$DOTNET_TOOL]}"
  elif $VERBOSE; then
    writeBlue ".NET tool $DOTNET_TOOL (${DOTNET_TOOLS[$DOTNET_TOOL]}) is already installed."
  fi
done
if ! [ -f "$DOTNET_TOOLS_DIR"/tye ]; then
  writeBlue "Install Tye."
  dotnet tool update --global Microsoft.Tye --prerelease
fi
if ! [ -f "$DOTNET_TOOLS_DIR"/dotnet-symbol ] || ! [ -d "$HOME"/.dotnet/sos ]; then
  writeBlue "Install .NET Symbol."
  dotnet tool update --global dotnet-symbol
  "$HOME"/.dotnet/tools/dotnet-sos install
fi

if $UPDATE; then
  updateDotnet () {
    if [ $# -lt 2 ]; then
      writeStdErrRed "'updateDotnet' needs at least 2 arguments."
      dump_stack
      return
    fi
    local TOOL_NAME=$1
    local TOOL_VERSION=$2
    if [ -v 3 ]; then
      local PRERELEASE="$3"
    else
      local PRERELEASE=''
    fi
    local AVAILABLE_TOOL_VERSION
    AVAILABLE_TOOL_VERSION=`dotnet tool search "$TOOL_NAME" "$PRERELEASE" | tail -n+3 | awk '{printf $1 ":"; print $2}' | (grep --color=never "^$TOOL_NAME:" || echo "$TOOL_NAME:") | cut -f2 -d':'`
    if [ "$AVAILABLE_TOOL_VERSION" == '' ]; then
      # search again if it fails, just to make sure
      AVAILABLE_TOOL_VERSION=`dotnet tool search "$TOOL_NAME" "$PRERELEASE" | tail -n+3 | awk '{printf $1 ":"; print $2}' | (grep --color=never "^$TOOL_NAME:" || echo "$TOOL_NAME:") | cut -f2 -d':'`
    fi
    if [ "$AVAILABLE_TOOL_VERSION" == '' ]; then
      writeBlue "Tool $TOOL_NAME seems to have changed names, installing the new one and uninstalling the old one."
      dotnet tool uninstall -g "$TOOL_NAME"
      dotnet tool update --global "`dotnet tool search "$TOOL_NAME" | tail -n+3 | awk '{print $1}'`"
    elif [ "$TOOL_VERSION" != "$AVAILABLE_TOOL_VERSION" ]; then
      writeBlue "Updating NET Tool $TOOL_NAME to $AVAILABLE_TOOL_VERSION."
      dotnet tool update --global "$TOOL_NAME" "$PRERELEASE"
    elif $VERBOSE; then
      writeBlue ".NET Tool $TOOL_NAME is version $AVAILABLE_TOOL_VERSION and does not need an update."
    fi
  }
  for TOOL_NAME_AND_VERSION in `dotnet tool list --global | tail -n +3 | awk '{printf $1 ":"; print $2}'`; do
    TOOL_NAME=`echo "$TOOL_NAME_AND_VERSION" | cut -f1 -d':'`
    TOOL_VERSION=`echo "$TOOL_NAME_AND_VERSION" | cut -f2 -d':'`
    PRERELEASE=''
    if echo "$TOOL_VERSION" | grep --color=never '-' > /dev/null; then
      PRERELEASE='--prerelease'
    fi
    updateDotnet "$TOOL_NAME" "$TOOL_VERSION" $PRERELEASE &
  done
  wait
fi

# node
export N_PREFIX=$HOME/.n
if ! hash node 2>/dev/null && ! [ -f "$HOME"/.n/bin/node ]; then
  writeBlue "Install Install latest Node version through n."
  "$BASEDIR"/tools/n/bin/n install latest
elif $UPDATE; then
  LATEST_NODE=`"$BASEDIR"/tools/n/bin/n ls-remote | head -n 2 | tail -n 1`
  if ! "$BASEDIR"/tools/n/bin/n ls | grep --color=never "$LATEST_NODE" -q; then
    writeBlue "Install Install latest Node version through n."
    "$BASEDIR"/tools/n/bin/n install latest
  fi
else
  if $VERBOSE; then
    writeBlue "Not installing Node.js version."
  fi
fi
export PATH="$N_PREFIX/bin:$PATH"
if ! hash yarn 2>/dev/null; then
  corepack enable # makes yarn available
fi

# npm tools
export NG_CLI_ANALYTICS=ci
NPM_PKGS_INSTALLED=$(npm ls -g --parseable --depth 0 | tail -n +2 | sed -E "s/$(npm prefix -g | sed 's/\//\\\//g')\/lib\/node_modules\///g" | sort)
NPM_PKGS_TO_INSTALL=`echo "@angular/cli
@githubnext/github-copilot-cli
bash-language-server
bats
bats-assert
bats-support
bower
cross-env
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
prettier
prettier-plugin-awk
trash-cli
typescript
vtop
yaml-cli" | sort`
# todo: prettier-plugin-awk is causing installation problems, see: https://github.com/Beaglefoot/prettier-plugin-awk/issues/18
NPM_PKGS_NOT_INSTALLED=`comm -23 <(echo "$NPM_PKGS_TO_INSTALL") <(echo "$NPM_PKGS_INSTALLED")`
if [ "$NPM_PKGS_NOT_INSTALLED" != "" ]; then
  # shellcheck disable=SC2086
  writeBlue Install packages $NPM_PKGS_NOT_INSTALLED with npm.
  # shellcheck disable=SC2086
  npm install -g $NPM_PKGS_NOT_INSTALLED
fi
if $UPDATE; then
  if [ "`npm outdated -g`" != '' ]; then
    writeBlue "Updating npm packages."
    npm update -g
  else
    if $VERBOSE; then
      writeBlue "Not installing Npm packages, they are already up to date."
    fi
  fi
elif $VERBOSE; then
  writeBlue "Not installing Npm packages, they are already installed."
fi

# krew tools
if [ -e "$HOME"/.krew/bin/kubectl-krew ]; then
  if ! [[ $PATH =~ $HOME/.krew/bin ]]; then
    export PATH=$PATH:$HOME/.krew/bin
  fi
  KREW_PLUGINS_INSTALLED=`kubectl krew list | tail -n+1 | awk '{print $1}' | sort -u`
  KREW_PLUGINS_TO_INSTALL=`echo "get-all
resource-capacity
sniff
tail" | sort`
  KREW_PLUGINS_NOT_INSTALLED=`comm -23 <(echo "$KREW_PLUGINS_TO_INSTALL") <(echo "$KREW_PLUGINS_INSTALLED")`
  if [ "$KREW_PLUGINS_NOT_INSTALLED" != "" ]; then
    writeBlue "Installing Krew plugins: $KREW_PLUGINS_NOT_INSTALLED"
    # shellcheck disable=SC2086
    kubectl krew install $KREW_PLUGINS_NOT_INSTALLED
  elif $VERBOSE; then
    writeBlue "Not installing krew plugins, they are already installed."
  fi
  if $UPDATE; then
    writeBlue "Updating Krew plugins."
    kubectl krew upgrade
  fi
else
  writeBlue "Krew not available, skipping..."
fi

# gem/ruby
if [ -e "$HOME"/.rbenv/bin/rbenv ]; then
  if ! [[ $PATH =~ $HOME/.rbenv/bin ]]; then
    export PATH="$HOME/.rbenv/shims:$HOME/.rbenv/bin:$PATH"
  fi
  GEMS_INSTALLED=`gem list -q --no-versions | sort`
  GEMS_TO_INSTALL="lolcat"
  GEMS_NOT_INSTALLED=`comm -23 <(echo "$GEMS_TO_INSTALL") <(echo "$GEMS_INSTALLED")`
  if [ "$GEMS_NOT_INSTALLED" != "" ]; then
    # shellcheck disable=SC2086
    writeBlue Install gems $GEMS_NOT_INSTALLED.
    # shellcheck disable=SC2086
    gem install $GEMS_NOT_INSTALLED
  else
    if $VERBOSE; then
      writeBlue "Not installing gems, they are already installed."
    fi
  fi
else
  writeBlue "Rbenv not available, skipping..."
fi

if [ -f "$HOME"/.cargo/env ]; then
  # shellcheck source=/dev/null
  source "$HOME/.cargo/env"
  # rust/cargo
  CRATES_INSTALLED=`cargo install --list | cut -f1 -d' ' | awk 'NF'`
  # todo: how to work with as-tree, which is not on crates.io?
  # See issue: https://github.com/jez/as-tree/issues/14
  CRATES_TO_INSTALL="bandwhich
cargo-update
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
nu
procs
sccache
tealdeer
tokei"
  CRATES_TO_INSTALL_NO_LOCK=""
  CRATES_NOT_INSTALLED=`comm -23 <(sort <(echo "$CRATES_TO_INSTALL")) <(sort <(echo "$CRATES_INSTALLED"))`
  if [ "$CRATES_NOT_INSTALLED" != "" ]; then
    writeBlue "Install crates $CRATES_NOT_INSTALLED."
    # shellcheck disable=SC2086
    cargo install --locked $CRATES_NOT_INSTALLED
  else
    if $VERBOSE; then
      writeBlue "Not installing crates, they are already installed."
    fi
  fi
  CRATES_NOT_INSTALLED_NO_LOCK=`comm -23 <(sort <(echo "$CRATES_TO_INSTALL_NO_LOCK")) <(sort <(echo "$CRATES_INSTALLED"))`
  if [ "$CRATES_NOT_INSTALLED_NO_LOCK" != "" ]; then
    # shellcheck disable=SC2086
    writeBlue Install crates $CRATES_NOT_INSTALLED_NO_LOCK without --locked.
    # shellcheck disable=SC2086
    cargo install $CRATES_NOT_INSTALLED_NO_LOCK
  else
    if $VERBOSE; then
      writeBlue "Not installing crates without --locked, they are already installed."
    fi
  fi
  if $UPDATE; then
    writeBlue "Updating crates."
    cargo install-update -a
  fi
fi

if [ -e "$HOME"/.go/bin/go ]; then
  export PATH=$PATH:$HOME/.go/bin
  if ! [[ -v GOPROXY ]]; then
    export GOPROXY=https://proxy.golang.org
  fi
  writeBlue "Installing go packages."
  declare -A GO_PKGS=(
    ["gox"]="mitchellh/gox"
    ["gup"]="nao1215/gup"
    ["manifest-tool"]="estesp/manifest-tool/v2/cmd/manifest-tool"
    ["shfmt"]="mvdan.cc/sh/v3/cmd/shfmt"
  )
  for PKG in "${!GO_PKGS[@]}"; do
    PKG_URL="${GO_PKGS[$PKG]}"
    if [[ "$PKG_URL" =~ ^[[:alnum:]]+(\.{1}[[:alnum:]]+)+ ]]; then
      FINAL_PKG_URL="$PKG_URL@latest"
    else
      FINAL_PKG_URL="github.com/$PKG_URL@latest"
    fi
    if ! hash "$PKG" 2>/dev/null; then
      writeBlue "Install go package $PKG ($FINAL_PKG_URL)."
      go install "$FINAL_PKG_URL"
    elif $VERBOSE; then
      writeBlue "Go package $PKG ($FINAL_PKG_URL) is already installed."
    fi
  done
  if $UPDATE; then
    writeBlue "Updating go packages."
    gup update
  fi
fi
